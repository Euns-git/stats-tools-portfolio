# KNHANES 2024 기반 당뇨 진행 단계별 위험요인 분석 (PPO Model)

국민건강영양조사(KNHANES) 2024년 자료를 이용하여 성인의 당뇨 진행 단계(정상 → 당뇨병전단계 → 당뇨병)에 따른 위험요인의 차별적 효과를 부분 비례오즈 모형(Partial Proportional Odds Model, PPO)으로 분석한 코드입니다.

> 논문: 성인의 당뇨 진행 단계별 위험요인의 차별적 효과: 국민건강영양조사(2024) 기반 부분 비례오즈 모형(Partial Proportional Odds Model) 적용

## ⚠️ 데이터 안내 (반드시 읽어주세요)

이 저장소에는 **원자료(raw data)가 포함되어 있지 않습니다.**

- 국민건강영양조사 원시자료(`HN24_ALL.sav` 등)는 질병관리청 국민건강영양조사 홈페이지(https://knhanes.kdca.go.kr)에서 **개별적으로 자료이용 신청 및 승인 절차를 거쳐야만** 내려받을 수 있습니다.
- 원시자료는 재배포가 금지되어 있으므로, 이 저장소뿐 아니라 어떤 형태로도 원자료 파일 자체를 커밋/업로드하지 않았습니다 (`.gitignore`로도 차단해 두었습니다).
- 이 코드를 실행하려면 원자료를 직접 신청해 받은 뒤, 코드 내 파일 경로(`HN24_ALL.sav`)에 맞게 저장하고 실행해야 합니다.

## 폴더 구성

```
.
├── analysis.R          # 전체 분석 코드 (전처리 ~ 모형적합 ~ 변수중요도 ~ 시각화)
├── figures/            # 논문 본문에는 지면 제한으로 싣지 못한 결과 시각화(Figure 2, 3)
├── README.md
└── .gitignore
```

## 사용 패키지

| 패키지 | 용도 |
|---|---|
| `haven` | .sav 원자료 불러오기 |
| `dplyr` | 데이터 전처리 |
| `tableone` | Table 2 기술통계 |
| `survey` | 복합표본설계 반영 (svydesign, svyglm) |
| `svyVGAM` | 복합표본설계 기반 순서형 로지스틱(PO/PPO) 모형 (svy_vglm) |
| `VGAM` | vglm 기반 AIC/BIC/LRT 비교, 순열중요도 refit용 |
| `aod` | Joint Wald Test |
| `openxlsx` | 결과 엑셀(.xlsx) 내보내기 |
| `ggplot2` | Forest plot 시각화 |

```r
install.packages(c("haven","dplyr","tableone","survey","svyVGAM",
                    "VGAM","aod","openxlsx","ggplot2"))
```

## 분석 파이프라인 (`analysis.R` 순서)

1. **데이터 전처리**: 원자료 로드, 당뇨 진행단계(`dm_status`) 및 예측변수 파생(허리둘레, 당뇨 가족력, 흡연상태, 스트레스, 주중-주말 수면시간 차이, 걷기 실천, 고혈압/이상지질혈증 여부 등)
2. **결측치 처리**: complete-case 필터링
3. **복합표본설계 선언**: `svydesign()` (층화변수/집락/가중치 반영)
4. **Table 2**: 대상자 특성 기술통계 (`tableone`)
5. **비례오즈 가정 검정**: 절단점별 이분형 로지스틱 모형 계수 비교 → 설계기반 Wald F-검정 (Table 3)
6. **모형 비교**: M0/M1/M2 단계적 모형의 AIC·BIC·LRT 비교 (Table 4; `vglm` 기반 pseudo-likelihood이므로 참고용 지표로만 활용하고, 실제 모형선택의 근거는 5번의 설계기반 Wald F-검정에 둠)
7. **최종 모형 적합**: PO 모형과 PPO 모형 (`svy_vglm`)
8. **Joint Wald Test (Table 6)**: 각 변수(군)의 계수가 모형 내에서 결합적으로 유의한지 검정 — "변수를 제거했을 때의 적합도 변화"가 아니라 현재 적합된 모형 내에서의 유의성 검정임에 유의
9. **5-fold 교차검증 기반 순열중요도(Permutation Importance)**: 층화 5-fold로 데이터를 분할하여 각 fold마다 훈련데이터(4개 fold)로 모형을 재적합하고, 검증데이터(나머지 1개 fold)에서만 변수를 순열(shuffle)하여 가중 로그손실(weighted log-loss) 증가량으로 변수중요도를 산출 (out-of-sample 평가)
10. **결과 내보내기**: Table 2~6 및 순열중요도 결과를 `tables_result.xlsx`로 저장
11. **Forest plot 생성**: PO vs PPO 오즈비 비교(Figure 2), PPO 유의변수만 표시(Figure 3) — 논문 본문에는 표/그림 개수 제한으로 게재하지 못해 본문에는 결과를 서술로만 제시하였고, 참고용으로 이 저장소에 이미지를 함께 올려둡니다.

## 참고

- 본 코드는 국내 학술지(보건정보통계학회지) 투고 규정상 논문 부록에는 포함하지 않았으며, 재현성 확인 및 참고 목적으로 GitHub에 공개합니다.
- 코드 실행 결과(수치)는 원자료 접근 승인 후 직접 실행해야 확인할 수 있습니다.
