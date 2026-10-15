"""
02_autograd_and_gradient_descent.py
자동미분, 경사하강법, optimizer, nn.Linear (Homework 2, 4, 5)
"""
import torch

# =====================================================================
# Part A. Autograd (Homework 2)
# =====================================================================

# --- 1. backward()는 grad를 누적한다 ---
x = torch.tensor([2.0], requires_grad=True)
z = x ** 2
z.backward()
print(x.grad)            # tensor([4.])   dz/dx = 2x = 4

z = x ** 2
z.backward()
print(x.grad)            # tensor([8.])   이전 값 4에 4가 더해짐

x.grad.zero_()           # 누적 방지: 매번 초기화
z = x ** 2
z.backward()
print(x.grad)            # tensor([4.])

# --- 2. Chain rule: y = x^3, z = 2y + sin(y) ---
x = torch.tensor([2.0], requires_grad=True)
y = x ** 3
z = 2 * y + torch.sin(y)
z.backward(retain_graph=True)     # 같은 그래프로 한 번 더 backward 하려면 필요
print(x.grad)                     # dz/dx = 3x^2 (2 + cos(x^3)) = 22.2540
x.grad.zero_()
y.backward()
print(x.grad)                     # dy/dx = 3x^2 = 12

# --- 3. 누적 기능으로 미니배치 score function 계산 ---
# X_i ~ Pois(theta): l(theta) = sum( X_i log(theta) - theta - log(X_i!) )
X_vals = torch.tensor([1, 3, 2, 5, 0, 2, 1, 3, 5, 0], dtype=torch.float32)
theta = torch.tensor([1.0], requires_grad=True)
total_ll = 0.0
for batch in X_vals.split(5):                    # 배치 크기 5, 순서 고정
    ll_batch = torch.sum(batch * torch.log(theta) - theta - torch.lgamma(batch + 1.0))
    total_ll += ll_batch.item()
    ll_batch.backward()                          # theta.grad에 배치별 기울기가 누적
print(total_ll, theta.grad)
# 배치별 ll = -12.2724, 누적 -24.5447
# score(theta=1) = sum(X_i / theta - 1): 배치별 6, 누적 12 -> 전체 데이터의 기울기와 일치

# --- 4. Jacobian: F(x1, x2) = (x1^2 + sin(x2), x1*x2 + exp(x1)) ---
x1 = torch.tensor([1.0], requires_grad=True)
x2 = torch.tensor([0.5], requires_grad=True)
f1 = x1 ** 2 + torch.sin(x2)
f2 = x1 * x2 + torch.exp(x1)

rows = []
f1.backward(retain_graph=True)                       # 1행: [df1/dx1, df1/dx2]
rows.append(torch.cat([x1.grad, x2.grad]))
x1.grad.zero_()
x2.grad.zero_()                                      # 누적 방지
f2.backward()                                        # 2행: [df2/dx1, df2/dx2]
rows.append(torch.cat([x1.grad, x2.grad]))
jacobian = torch.stack(rows)                         # (2, 2)

analytic = torch.tensor([[2 * x1.item(), torch.cos(x2).item()],
                         [x2.item() + torch.exp(x1).item(), x1.item()]])
print(jacobian, analytic)                            # 두 결과가 일치

# =====================================================================
# Part B. Linear regression by gradient descent (Homework 4)
# =====================================================================
X1 = torch.tensor([0.83, -0.18, 0.27, 0.32, 0.25, -0.73, 0.19, -0.08, -0.47, -0.28,
                   -0.23, 0.25, 0.15, 0.92, 1.27, -0.50, 0.05, -0.74, -0.06, 0.70])
X2 = torch.tensor([0.63, -1.43, -1.35, 0.70, -1.48, 0.06, 1.14, 0.96, -1.65, 0.44,
                   0.62, 0.47, -0.08, 1.03, 1.24, -0.54, 0.08, 0.85, -1.53, 0.66])
Y = torch.tensor([0.50, 1.34, 1.39, 0.40, 1.20, 0.11, -0.21, -0.26, 1.18, 0.59,
                  0.13, 0.17, 0.55, 0.32, 0.19, 0.46, 0.32, -0.35, 1.35, 0.20])
n = len(Y)


def predict(X1, X2, b0, b1, b2):
    return b0 + b1 * X1 + b2 * X2


def sse(Y, Y_hat):
    return torch.sum((Y - Y_hat) ** 2)


def fresh_params():
    """매 실험마다 파라미터를 0으로 새로 초기화 (이전 학습 결과가 이어지지 않도록)."""
    return [torch.tensor([0.0], requires_grad=True) for _ in range(3)]


# 손실은 SSE로 정의하고 grad를 얻은 뒤, 보고할 오차는 MSE = SSE / n 으로 계산
beta0, beta1, beta2 = fresh_params()
lr, epochs = 0.0001, 5000
for i in range(epochs):
    loss = sse(Y, predict(X1, X2, beta0, beta1, beta2))
    beta0.grad = beta1.grad = beta2.grad = None      # grad 초기화
    loss.backward()
    with torch.no_grad():                            # 파라미터 수동 업데이트
        beta0 -= lr * beta0.grad
        beta1 -= lr * beta1.grad
        beta2 -= lr * beta2.grad
    if i % 500 == 0:
        print(f"Epoch {i:4d}: SSE={loss.item():.6f}")
# lr=0.0001, 5000 epochs 후 (0.4677, 0.3541, -0.5555): 학습률이 작아 최소해에 천천히 접근
# lr=0.05는 발산(NaN). SSE는 합이라 기울기가 커서 학습률을 작게 잡아야 한다.
mse = sse(Y, predict(X1, X2, beta0, beta1, beta2)).item() / n
print(beta0.item(), beta1.item(), beta2.item(), mse)

# =====================================================================
# Part C. Exponential distribution: quantile by formula, icdf, optimization
# =====================================================================
rate = torch.tensor([1.3])
exp_dist = torch.distributions.Exponential(rate=rate)

# 손 계산: F(x) = 1 - exp(-rate * x),  F(x0) = 0.95  ->  x0 = -ln(0.05) / rate = 2.3044
print(exp_dist.cdf(torch.tensor([2.0])))             # 0.9257
print(1 - torch.exp(-rate * 2.0))                    # 손 계산 1 - exp(-1.3 * 2) 와 일치
print(exp_dist.icdf(torch.tensor([0.95])))           # 2.3044

# 경사 기반 최적화: L(x0) = (CDF(x0) - 0.95)^2 를 최소화
x0 = torch.tensor([0.01], requires_grad=True)
optimizer = torch.optim.Adam([x0], lr=0.1)
for step in range(1000):
    optimizer.zero_grad()
    loss = (exp_dist.cdf(x0) - 0.95) ** 2
    loss.backward()
    optimizer.step()
print(x0.item())                                     # 약 2.304 (icdf 결과와 거의 동일)

# =====================================================================
# Part D. Optimizers and torch.nn.Linear (Homework 5)
# =====================================================================
X = torch.stack([X1, X2], dim=1)       # (n, 2): 두 설명변수를 열로 쌓기
Yc = Y.reshape(-1, 1)                  # (n, 1): nn.Linear 출력 모양에 맞춤


def mse_of(pred):
    """학습된 모형의 MSE = SSE / n."""
    return torch.mean((Yc - pred) ** 2).item()


# (i) optimizer(SGD) 사용, 직접 만든 파라미터
beta0, beta1, beta2 = fresh_params()
optimizer = torch.optim.SGD([beta0, beta1, beta2], lr=0.01)
for i in range(2000):
    loss = sse(Y, predict(X1, X2, beta0, beta1, beta2))
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
pred_i = predict(X1, X2, beta0, beta1, beta2).detach().reshape(-1, 1)
print("(i)", beta0.item(), beta1.item(), beta2.item(), mse_of(pred_i))
# (0.4672, 0.3583, -0.5565), MSE 0.0235


def train_linear(X_in, bias, use_optimizer, lr, epochs):
    """nn.Linear 모델을 새로 만들어 SSE 손실로 학습."""
    model = torch.nn.Linear(in_features=X_in.shape[1], out_features=1, bias=bias)
    criterion = torch.nn.MSELoss(reduction="sum")           # SSE
    if use_optimizer:
        optimizer = torch.optim.SGD(model.parameters(), lr=lr)
    for i in range(epochs):
        loss = criterion(model(X_in), Yc)
        model.zero_grad()
        loss.backward()
        if use_optimizer:
            optimizer.step()
        else:
            with torch.no_grad():                          # optimizer 없이 수동 업데이트
                for param in model.parameters():
                    param -= lr * param.grad
    return model


# (ii) nn.Linear(bias=True) + optimizer
m_ii = train_linear(X, bias=True, use_optimizer=True, lr=0.01, epochs=2000)
# (iii) nn.Linear(bias=True), optimizer 없이 수동 경사하강법 (모델을 새로 만들어 학습)
m_iii = train_linear(X, bias=True, use_optimizer=False, lr=0.01, epochs=2000)
# (iv) nn.Linear(bias=False): 절편을 모형에서 빼는 것이 아니라,
#      설계행렬에 1로 된 열을 붙여 절편 beta0를 가중치로 추정한다.
X_aug = torch.cat([torch.ones(n, 1), X], dim=1)             # (n, 3): [1, X1, X2]
m_iv = train_linear(X_aug, bias=False, use_optimizer=True, lr=0.01, epochs=2000)

with torch.no_grad():
    for name, m, inp in [("(ii)", m_ii, X), ("(iii)", m_iii, X), ("(iv)", m_iv, X_aug)]:
        print(name, m.weight.data, None if m.bias is None else m.bias.data, mse_of(m(inp)))
# (ii)-(iv) 모두 최소제곱해 (0.4672, 0.3583, -0.5565), MSE 0.0235와 일치해야 한다.
