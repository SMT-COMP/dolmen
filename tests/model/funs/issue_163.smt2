(set-logic QF_UF)
(declare-sort x152 0)
(declare-fun x156 () x152)
(declare-fun x53 () x152)
(assert (not (= x53 x156)))
(declare-fun x310 () x152)
(assert (= x310 x53))
(check-sat)
(exit)
