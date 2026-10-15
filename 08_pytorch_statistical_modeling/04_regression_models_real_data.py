"""
04_regression_models_real_data.py
실제 데이터에 커스텀 NLL 모형 적용 (Homework 7)
  1. Boston housing   : Gaussian 회귀 (medv ~ lstat + age vs medv ~ lstat), test MSE 비교
  2. warpbreaks       : Poisson 회귀 3개 모형을 AIC로 비교
  3. Default          : 로지스틱 회귀 2개 모형을 test accuracy로 비교
데이터 파일(Boston.csv, warpbreaks.csv, Default_data.csv)은 저장소에 포함되어 있지 않다.
"""
import csv

import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


def split_70_30(data):
    """행을 섞은 뒤 70% train / 30% test로 분할."""
    n = data.shape[0]
    shuffled = data[torch.randperm(n)]
    n_train = int(n * 0.7)
    return shuffled[:n_train], shuffled[n_train:]


def standardize(train_cols, test_cols):
    """train 평균/표준편차로 train, test를 모두 표준화 (test 정보 누수 방지)."""
    mean, sd = train_cols.mean(dim=0), train_cols.std(dim=0)
    return (train_cols - mean) / sd, (test_cols - mean) / sd


def sgd_fit(model, loader, lr, epochs, columns=None):
    """미니배치 SGD. columns로 설계행렬의 사용할 열을 선택."""
    optimizer = torch.optim.SGD(model.parameters(), lr=lr)
    history = []
    for epoch in range(epochs):
        total = 0.0
        for xx, yy in loader:
            if columns is not None:
                xx = xx[:, columns]
            out = model(xx)
            loss = model.loss(out, yy)
            loss.backward()
            optimizer.step()
            optimizer.zero_grad()
            total += loss.item()
        history.append(total)
    return history


# =====================================================================
# 1. Boston housing: Gaussian regression
# =====================================================================
df = pd.read_csv("Boston.csv")      # 열: crim, zn, indus, chas, nox, rm, age, dis, rad, tax, ptratio, lstat, medv
data = torch.tensor(df.values, dtype=torch.float32)
train, test = split_70_30(data)
X_train, y_train = train[:, :-1], train[:, -1:]                 # 마지막 열 medv가 반응변수
X_test, y_test = test[:, :-1], test[:, -1:]

idx_age = df.columns.get_loc("age")
idx_lstat = df.columns.get_loc("lstat")


def design_matrix(cols):
    """선택한 열을 표준화하고 절편 열을 맨 앞에 붙인다."""
    tr, te = standardize(X_train[:, cols], X_test[:, cols])
    ones_tr, ones_te = torch.ones(tr.shape[0], 1), torch.ones(te.shape[0], 1)
    return torch.cat([ones_tr, tr], dim=1), torch.cat([ones_te, te], dim=1)


class GaussianRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.randn([p, 1]))
        self.log_sigma = nn.Parameter(torch.zeros(1))        # sigma = exp(.) > 0

    def forward(self, X):
        return X @ self.betas

    def loss(self, mu, y):
        sigma2 = torch.exp(self.log_sigma) ** 2
        ll = -0.5 * torch.log(2 * torch.pi * sigma2) - (y - mu) ** 2 / (2 * sigma2)
        return -torch.sum(ll)


def boston_test_mse(cols, lr=0.005, epochs=1000):
    """두 모형을 같은 학습률/에폭으로 학습해 공정하게 비교."""
    Xtr, Xte = design_matrix(cols)
    torch.manual_seed(0)       # 두 모형이 같은 초기값/같은 batch 순서를 쓰도록 시드 고정
    loader = DataLoader(TensorDataset(Xtr, y_train), shuffle=True, batch_size=20)
    model = GaussianRegModel(Xtr.shape[1])
    sgd_fit(model, loader, lr, epochs)
    with torch.no_grad():
        return torch.mean((y_test - model(Xte)) ** 2).item(), model


mse_two, model_two = boston_test_mse([idx_lstat, idx_age])   # Model 1: lstat + age
mse_one, model_one = boston_test_mse([idx_lstat])            # Model 2: lstat only
mse_null = torch.mean((y_test - y_train.mean()) ** 2).item() # 기준선: train 평균으로만 예측
print(mse_two, mse_one, mse_null)

# =====================================================================
# 2. warpbreaks: Poisson regression and AIC
# =====================================================================
rows = []
with open("warpbreaks.csv") as f:
    reader = csv.reader(f)
    next(reader)                                             # header: breaks, wool, tension
    rows = list(reader)

tension_map = {"L": (0.0, 0.0), "M": (1.0, 0.0), "H": (0.0, 1.0)}   # L이 기준 범주
wool_map = {"A": 0.0, "B": 1.0}                                      # A가 기준 범주
data = torch.tensor(
    [[float(b), 1.0, *tension_map[t], wool_map[w]] for b, w, t in rows],
    dtype=torch.float32)       # 열: breaks, 절편, tension_M, tension_H, wool_B
train, test = split_70_30(data)
y_train, X_train = train[:, 0:1], train[:, 1:]
y_test, X_test = test[:, 0:1], test[:, 1:]
loader = DataLoader(TensorDataset(X_train, y_train), shuffle=True, batch_size=10)


class PoissonRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.zeros(p, 1))

    def forward(self, X):
        return torch.exp(X @ self.betas)

    def loss(self, lam, y):
        ll = y * torch.log(lam + 1e-8) - lam - torch.lgamma(y + 1)
        return -torch.sum(ll)


def fit_poisson_aic(columns):
    """선택한 열로 Poisson MLE를 구하고 AIC = 2k + 2 * NLL 계산."""
    torch.manual_seed(0)       # 모형마다 같은 batch 순서를 쓰도록 시드 고정
    model = PoissonRegModel(len(columns))
    sgd_fit(model, loader, lr=0.001, epochs=500, columns=columns)
    with torch.no_grad():
        nll = model.loss(model(X_train[:, columns]), y_train).item()   # 해당 모형의 NLL 사용
    return model, 2 * len(columns) + 2 * nll


m1, aic1 = fit_poisson_aic([0, 3])           # breaks ~ wool
m2, aic2 = fit_poisson_aic([0, 1, 2])        # breaks ~ tension
m3, aic3 = fit_poisson_aic([0, 1, 2, 3])     # breaks ~ wool + tension
print(aic1, aic2, aic3)                      # AIC가 가장 작은 모형을 선택

# =====================================================================
# 3. Default: logistic regression and test accuracy
# =====================================================================
rows = []
with open("Default_data.csv") as f:
    reader = csv.reader(f)
    next(reader)                                             # header: default, student, balance, income
    rows = list(reader)

data = torch.tensor(
    [[float(b), float(i), 1.0 if s.lower() == "yes" else 0.0, 1.0 if d.lower() == "yes" else 0.0]
     for d, s, b, i in rows],
    dtype=torch.float32)       # 열: balance, income, student, default(반응변수)
train, test = split_70_30(data)
X_train, y_train = train[:, :-1], train[:, -1:]
X_test, y_test = test[:, :-1], test[:, -1:]

# balance와 income은 단위가 크게 달라 표준화 필요; student(0/1)는 그대로
Z_train, Z_test = standardize(X_train[:, [0, 1]], X_test[:, [0, 1]])
XXX_train = torch.cat([torch.ones(X_train.shape[0], 1), Z_train, X_train[:, [2]]], dim=1)
XXX_test = torch.cat([torch.ones(X_test.shape[0], 1), Z_test, X_test[:, [2]]], dim=1)
# 열 순서: 절편(0), balance(1), income(2), student(3)
train_loader = DataLoader(TensorDataset(XXX_train, y_train), shuffle=True, batch_size=100)
test_loader = DataLoader(TensorDataset(XXX_test, y_test), shuffle=False, batch_size=100)


class LogisticRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.zeros(p, 1))

    def forward(self, X):
        return torch.sigmoid(X @ self.betas)

    def loss(self, pp, y):
        eps = 1e-8
        ll = y * torch.log(pp + eps) + (1 - y) * torch.log(1 - pp + eps)
        return -torch.sum(ll)


def logistic_accuracy(columns):
    torch.manual_seed(0)       # 모형마다 같은 batch 순서를 쓰도록 시드 고정
    model = LogisticRegModel(len(columns))
    sgd_fit(model, train_loader, lr=0.001, epochs=500, columns=columns)
    correct = 0
    with torch.no_grad():
        for xx, yy in test_loader:
            pred = (model(xx[:, columns]) >= 0.5).float()
            correct += (pred == yy).sum().item()
    return correct / len(test_loader.dataset), model


acc1, _ = logistic_accuracy([0, 2, 3])       # Model 1: student + income
acc2, _ = logistic_accuracy([0, 1, 2, 3])    # Model 2: student + income + balance
print(acc1, acc2)                            # 제출 결과: 0.968 vs 0.975 (balance 포함 모형이 더 높음)
