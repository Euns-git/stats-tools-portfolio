"""
01_numpy_and_torch_basics.py
NumPy 배열 연산과 PyTorch 텐서 기초 (Homework 1-2)
"""
import numpy as np
import torch

# =====================================================================
# Part A. NumPy array operations
# =====================================================================
A = np.array([[1, 2, 5, 1],
              [3, 4, 1, 0]])

def subtract_row_means(A):
    """각 행의 평균을 빼기: axis=1 평균을 (n,1) 열벡터로 바꿔 브로드캐스팅."""
    return A - A.mean(axis=1).reshape([-1, 1])


def subtract_col_means(A):
    """각 열의 평균을 빼기: axis=0 평균을 (1,p) 행벡터로 바꿔 브로드캐스팅."""
    return A - A.mean(axis=0).reshape([1, -1])


def concat_columns(A, B):
    """(n,p)와 (n,q)를 옆으로 이어 붙여 (n,p+q)로: axis=1."""
    return np.concatenate((A, B), axis=1)


def concat_rows(A, B):
    """(n,p)와 (m,p)를 위아래로 이어 붙여 (n+m,p)로: axis=0."""
    return np.concatenate((A, B), axis=0)


A_row_centered = subtract_row_means(A)
A_col_centered = subtract_col_means(A)

B1 = np.array([[4.5, 3.5], [5.1, 2.3]])
C1 = np.array([[1], [2]])
side_by_side = concat_columns(B1, C1)

D1 = np.array([[4, 3], [5, 2], [1, 1]])
stacked_rows = concat_rows(B1, D1)

# 가장자리는 1, 안쪽은 0인 10x10 행렬
border = np.ones([10, 10])
border[1:-1, 1:-1] = 0


def moving_average(arr, k):
    """길이 k 윈도우의 이동평균. 결과 길이는 n - k + 1."""
    n = len(arr)
    result = []
    for i in range(n - k + 1):
        window = arr[i:i + k]
        result.append(sum(window) / k)
    return result


ma = moving_average([3, 5, 7, 2, 8, 10, 11, 65, 72, 81, 99, 100, 150], k=3)

# 3차원 배열: (ID, Year) 별 사고 횟수, 소득, 스포츠카 여부를 (3, 5, 3)으로 쌓기
N = np.array([[0, 1, 0, 1, 2], [1, 3, 2, 1, 0], [0, 0, 0, 1, 3]])
Salary = np.array([[157, 167, 130, 145, 170],
                   [250, 260, 263, 273, 290],
                   [301, 120, 30, 100, 502]])
Sports = np.array([[1, 1, 1, 1, 1], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]])

Y = np.stack([N, Salary, Sports], axis=2)        # (3, 5, 3): 변수 축이 마지막
Y2 = np.stack([N, Salary, Sports], axis=1)       # (3, 3, 5): 변수 축이 가운데
assert np.array_equal(np.transpose(Y, (0, 2, 1)), Y2)   # 축 교환으로 동일

# 행렬곱으로 파생변수 계산 (반복문 없이): Net asset = Income - Loss + Stock, Wealth = Stock + House
# X: (ID, Year, [Income, Loss, Stock, House])
W = np.array([[1, 0], [-1, 0], [1, 1], [0, 1]])
# Y_asset = X @ W    # X가 (10, 5, 4)일 때 결과는 (10, 5, 2)

# 결측값(NaN)이 있는 행렬의 행별 표준화
M = np.array([[500, 520, 540, 560],
              [3.0, np.nan, 2.5, 2.0],
              [50, 52, 55, 57],
              [90, 100, 100, 110]])
mu = np.nanmean(M, axis=1)
sigma = np.nanstd(M, axis=1, ddof=0)              # 모표준편차
M_norm = (M - mu[:, None]) / sigma[:, None]       # (4,1)로 늘려야 행별로 계산됨
M_rec = sigma[:, None] * M_norm + mu[:, None]     # 복원 후 M과 비교

# 브로드캐스팅과 augmented design trick: Yhat = XW + c  vs  [1, X] @ [c; W]
X = np.array([[160, 55, 170, 65], [165, 60, 175, 70], [170, 58, 180, 72]])
Wt = np.array([[0.5, 0.1], [0.2, 0.3], [0.4, 0.2], [0.1, 0.4]])
c = np.array([[1.0, 2.0]])

Yhat = X @ Wt + c                                             # (3, 2)
X_a = np.concatenate([np.ones((X.shape[0], 1)), X], axis=1)   # (3, 5)
W_a = np.concatenate([c, Wt], axis=0)                         # (5, 2)
assert np.allclose(Yhat, X_a @ W_a)

# =====================================================================
# Part B. PyTorch tensors and loops
# =====================================================================


def row_sums_loop(A):
    """2차원 텐서의 각 행의 합을 for문으로 계산해 list로 반환."""
    result = []
    for row in A:
        s = 0
        for element in row:
            s += element.item()      # 텐서 -> 파이썬 숫자
        result.append(s)
    return result


def transpose_loop(A):
    """중첩 for문으로 전치행렬 계산."""
    nrow, ncol = A.shape
    A_T = torch.zeros(ncol, nrow)
    for i in range(nrow):
        for j in range(ncol):
            A_T[j, i] = A[i, j]
    return A_T


def run_length_encode(seq):
    """연속된 같은 값을 (값, 반복 횟수) 두 list로 압축."""
    values, counts = [], []
    prev = seq[0].item()
    count = 1
    for cc in seq[1:]:
        val = cc.item()
        if val == prev:
            count += 1
        else:
            values.append(prev)
            counts.append(count)
            prev, count = val, 1
    values.append(prev)
    counts.append(count)
    return values, counts


if __name__ == "__main__":
    T = torch.tensor([[1, 2, 3], [4, 5, 6]])
    print(row_sums_loop(T))                                   # [6, 15]
    print(transpose_loop(T))
    print(run_length_encode(torch.tensor([1, 1, 1, 2, 2, 3, 3, 3, 3, 2])))
    # ([1, 2, 3, 2], [3, 2, 4, 1])
