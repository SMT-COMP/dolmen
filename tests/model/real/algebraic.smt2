(set-logic NRA)
(declare-fun sqrt2 () Real)
(assert (= (* sqrt2 sqrt2) 2.0))
(check-sat)