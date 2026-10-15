"""
03_likelihood_based_regression.py
음의 로그가능도(NLL)를 손실로 쓰는 커스텀 모형 (Homework 6)
Gaussian / Poisson / Logistic 회귀를 nn.Module로 구현하고, nn.Linear 버전과 비교한다.
시뮬레이션 데이터를 쓰므로 외부 데이터 없이 실행된다.
"""
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


def make_loaders(X, y, n_train=1000, batch_size=20):
    """앞 1000개는 train, 나머지는 test로 분할."""
    train = TensorDataset(X[:n_train], y[:n_train].reshape([-1, 1]))
    test = TensorDataset(X[n_train:], y[n_train:].reshape([-1, 1]))
    return (DataLoader(train, shuffle=True, batch_size=batch_size),
            DataLoader(test, shuffle=False, batch_size=batch_size))


def fit(model, loader, optimizer, epochs):
    """미니배치 SGD로 model.loss(= NLL)를 최소화."""
    history = []
    for epoch in range(epochs):
        model.train()
        total = 0.0
        for xx, yy in loader:
            out = model(xx)
            loss = model.loss(out, yy)
            loss.backward()
            optimizer.step()
            optimizer.zero_grad()
            total += loss.item()
        history.append(total / len(loader))
    return history


@torch.no_grad()
def test_mse(model, loader):
    model.eval()
    sq_error, n_test = 0.0, 0
    for xx, yy in loader:
        sq_error += torch.sum((yy - model(xx)) ** 2).item()
        n_test += yy.shape[0]
    return sq_error / n_test


@torch.no_grad()
def test_accuracy(model, loader):
    model.eval()
    correct, n_test = 0, 0
    for xx, yy in loader:
        pred = (model(xx) >= 0.5).float()
        correct += (pred == yy).sum().item()
        n_test += yy.shape[0]
    return correct / n_test


# =====================================================================
# 1. Gaussian regression: y = 2 + 0.8 x1 - 1.2 x2 + 3 x3 + N(0, 2^2)
# =====================================================================
torch.manual_seed(452)
n = 2000
x1 = torch.randn(n)
x2 = torch.normal(mean=0.0, std=2.0, size=(n,))
x3 = torch.bernoulli(torch.full((n,), 0.5))
y = 2.0 + 0.8 * x1 - 1.2 * x2 + 3.0 * x3 + torch.normal(mean=0.0, std=2.0, size=(n,))
X = torch.stack((torch.ones(n), x1, x2, x3), dim=1)         # (n, 4): 절편 포함
train_loader, test_loader = make_loaders(X, y)


class GaussianRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.zeros(p, 1))
        self.log_sigma = nn.Parameter(torch.tensor(0.0))     # sigma = exp(.) > 0 보장

    def forward(self, X):
        return X @ self.betas                                # mu

    def loss(self, mu, y):
        sigma2 = torch.exp(self.log_sigma) ** 2
        ll = -0.5 * (torch.log(2 * torch.pi * sigma2) + (y - mu) ** 2 / sigma2)
        return -torch.sum(ll)


gauss = GaussianRegModel(4)
fit(gauss, train_loader, torch.optim.SGD(gauss.parameters(), lr=0.01), epochs=100)
print(gauss.betas.data.flatten(), torch.exp(gauss.log_sigma).item())
# betas = (1.86, 0.80, -1.28, 2.99), sigma = 1.79   (참값: 2.0, 0.8, -1.2, 3.0 / sigma 2.0)
print(test_mse(gauss, test_loader))                          # 4.13

# nn.Linear + MSELoss 버전 (가우시안 MLE의 betas는 최소제곱해와 같다)
lin = nn.Linear(in_features=4, out_features=1, bias=True)
criterion = nn.MSELoss(reduction="mean")
opt = torch.optim.SGD(lin.parameters(), lr=0.001)
for epoch in range(1000):
    for xx, yy in train_loader:
        loss = criterion(lin(xx), yy)
        opt.zero_grad()
        loss.backward()
        opt.step()
print(test_mse(lin, test_loader))                            # 4.07

# =====================================================================
# 2. Poisson regression: log(mu) = -2 + 0.4 x1 - 1.2 x2 + 1.0 x3
# =====================================================================
torch.manual_seed(452)
x1 = torch.randn(n)
x2 = torch.randn(n)
x3 = torch.bernoulli(torch.full((n,), 0.5))
mu = torch.exp(-2.0 + 0.4 * x1 - 1.2 * x2 + 1.0 * x3)
y = torch.distributions.Poisson(mu).sample()
X = torch.stack((torch.ones(n), x1, x2, x3), dim=1)
train_loader, test_loader = make_loaders(X, y)


class PoissonRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.zeros(p, 1))

    def forward(self, X):
        return torch.exp(X @ self.betas)                     # lambda = exp(X beta): 로그 연결함수

    def loss(self, lam, y):
        ll = y * torch.log(lam) - lam - torch.lgamma(y + 1)
        return -torch.sum(ll)


pois = PoissonRegModel(4)
fit(pois, train_loader, torch.optim.SGD(pois.parameters(), lr=0.001), epochs=500)
print(pois.betas.data.flatten())      # (-2.00, 0.37, -1.18, 1.03)   참값: (-2.0, 0.4, -1.2, 1.0)
print(test_mse(pois, test_loader))    # 0.417


# nn.Linear 버전: 선형결합은 nn.Linear(bias=False), X에 이미 절편 열이 있음
class PoissonRegLinear(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.linear = nn.Linear(input_dim, 1, bias=False)

    def forward(self, x):
        return torch.exp(self.linear(x))

    def loss(self, lam, y):
        ll = y * torch.log(lam) - lam - torch.lgamma(y + 1)
        return -torch.sum(ll)


pois_lin = PoissonRegLinear(4)
fit(pois_lin, train_loader, torch.optim.SGD(pois_lin.parameters(), lr=0.001), epochs=500)
print(pois_lin.linear.weight.data, test_mse(pois_lin, test_loader))   # 0.422

# =====================================================================
# 3. Logistic regression: logit(p) = -2 + 0.4 x1 - 1.2 x2 + 1.0 x3
# =====================================================================
torch.manual_seed(452)
x1 = torch.randn(n)
x2 = torch.randn(n)
x3 = torch.bernoulli(torch.full((n,), 0.5))
p = torch.sigmoid(-2.0 + 0.4 * x1 - 1.2 * x2 + 1.0 * x3)
y = torch.distributions.Bernoulli(probs=p).sample()
X = torch.stack((torch.ones(n), x1, x2, x3), dim=1)
train_loader, test_loader = make_loaders(X, y)


class LogisticRegModel(nn.Module):
    def __init__(self, p):
        super().__init__()
        self.betas = nn.Parameter(torch.zeros(p, 1))

    def forward(self, X):
        return torch.sigmoid(X @ self.betas)                 # 확률 p

    def loss(self, pp, y):
        eps = 1e-10                                          # log(0) 방지
        ll = y * torch.log(pp + eps) + (1 - y) * torch.log(1 - pp + eps)
        return -torch.sum(ll)


logit = LogisticRegModel(4)
fit(logit, train_loader, torch.optim.SGD(logit.parameters(), lr=0.001), epochs=500)
print(logit.betas.data.flatten())     # (-2.16, 0.36, -1.20, 1.15)   참값: (-2.0, 0.4, -1.2, 1.0)
print(test_mse(logit, test_loader))   # 0.141
print(test_accuracy(logit, test_loader))   # 0.799
