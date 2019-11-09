extensions [fuzzy]

;;;;;;;;;;;;;;;;;
;;; Variables ;;;
;;;;;;;;;;;;;;;;;

globals [
  r1-param1
  r1-param2

  r2-param1
  r2-param2

  r1-res
  r2-res

  degree-of-consistency-R1
  degree-of-consistency-R2

  reshaped-consequent-R1
  reshaped-consequent-R2
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to startup
  clear-all
  create-fuzzy-sets
  compute-suitability
  do-plots
end

to create-fuzzy-sets
  let lr (list r1p1_max r1p1_dev (list r1p1_min_X r1p1_max_X))
  set r1-param1          fuzzy:gaussian-set lr

  let hr (list r2p1_max r2p1_dev (list r2p1_min_X r2p1_max_X))
  set r2-param1         fuzzy:gaussian-set hr

  let ctm (list r2p2_max r2p2_dev (list r2p2_min_X r2p2_max_X))
  set r2-param2       fuzzy:gaussian-set ctm

  let ffm (list r1p2_max r1p2_dev (list r1p2_min_X r1p2_max_X))
  set r1-param2       fuzzy:gaussian-set ffm

  let nid (list res1_max res1_dev (list res1_min_X res1_max_X))
  set r1-res    fuzzy:gaussian-set nid

  let id (list res2_max res2_dev (list res2_min_X res2_max_X))
  set r2-res     fuzzy:gaussian-set id
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Run-time procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to compute-suitability

  create-fuzzy-sets

  ;; COMPUTATION OF DEGREES OF CONSISTENCY BETWEEN FACTS (INPUTS) AND ANTECEDENTS FOR EACH RULE

  ;; Rule 1: IF (House is Inr2-param1 OR/AND Close-to-work)...
  let degree-of-consistency-R1a fuzzy:evaluation-of r1-param1 Param_1_level
  let degree-of-consistency-R1b fuzzy:evaluation-of r1-param2 Param_2_level
  let type1 0
  ifelse type-R1 = "OR" [set type1 type-of-or][set type1 type-of-and]
  set degree-of-consistency-R1 (runresult (word type1" list degree-of-consistency-R1a degree-of-consistency-R1b"))

  ;; Rule 2: IF (House is Expensive OR/AND Far-from-work)...
  let degree-of-consistency-R2a fuzzy:evaluation-of r2-param1 Param_1_level
  let degree-of-consistency-R2b fuzzy:evaluation-of r2-param2 Param_2_level
  let type2 0
  ifelse type-R2 = "OR" [set type2 type-of-or][set type2 type-of-and]
  set degree-of-consistency-R2 (runresult (word type2 " list degree-of-consistency-R2a degree-of-consistency-R2b"))


  ;; COMPUTATION OF RESHAPED CONSEQUENTS FOR EACH RULE

  ;; Rule 1: ... THEN Suitability is Good.
  set reshaped-consequent-R1 (runresult (word "fuzzy:" reshaping-method " r1-res degree-of-consistency-R1"))

  ;; Rule 2: ... THEN Suitability is Low.
  set reshaped-consequent-R2 (runresult (word "fuzzy:" reshaping-method " r2-res degree-of-consistency-R2"))

end

;;;;;;;;;;;;;;;;;;;;;;;;
;;;      Plots       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to do-plots
  clear-all-plots

  set-current-plot "R1_Param_1"
  draw r1-param1 Param_1_level 100

  set-current-plot "R2_Param_1"
  draw r2-param1 Param_1_level 100


  set-current-plot "R2_Param_2"
  draw r2-param2 Param_2_level 100

  set-current-plot "R1_Param_2"
  draw r1-param2 Param_2_level 100


  set-current-plot "R1_Result"
    fuzzy:plot r1-res
    set-current-plot-pen "green"
    fuzzy:plot reshaped-consequent-R1

  set-current-plot "R2_result"
    fuzzy:plot r2-res
    set-current-plot-pen "green"
    fuzzy:plot reshaped-consequent-R2

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Supporting procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report prob-or [l]
  report (first l) + (last l) * (1 - (first l))
end

to-report product [l]
  report (first l) * (last l)
end

to draw [fuzzy-set v1 v2]
  fuzzy:plot fuzzy-set
  plot-pen-up
  plotxy v1 0
  plot-pen-down
  set-plot-pen-mode 0
  plotxy v1 (fuzzy:evaluation-of fuzzy-set v1)
  plotxy v2 (fuzzy:evaluation-of fuzzy-set v1)
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; fuzzy-system-of-IF-THEN-rules
;; fuzzy-system-of-IF-THEN-rules is a model designed to show how to implement
;; a system of fuzzy IF-THEN rules in NetLogo.
;;
;; Copyright (C) 2015 Luis R. Izquierdo, Segismundo S. Izquierdo & Doina Olaru
;;
;; This program is free software: you can reParam_2_levelribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is Param_2_levelributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; Contact information:
;; Luis R. Izquierdo
;;   University of Burgos, Spain.
;;   e-mail: lrizquierdo@ubu.es
;;
;;
;; Adapted by Enrique José López Ortiz to calculate parameters of fuzzy-sets in evacuation scenario
;; email: e.l.o.universidad@gmail.com
;;
@#$#@#$#@
GRAPHICS-WINDOW
235
87
408
151
-1
-1
27.5
1
1
1
1
1
0
0
0
1
0
5
0
1
0
0
1
ticks
30.0

BUTTON
283
317
363
352
compute
compute-suitability\ndo-plots
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
230
87
430
237
R1_Param_1
p
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"mine" 1.0 0 -13345367 true "" ""

SLIDER
95
281
262
314
Param_1_level
Param_1_level
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
95
321
262
354
Param_2_level
Param_2_level
0
100
67.0
1
1
NIL
HORIZONTAL

PLOT
227
413
427
563
R2_Param_1
p
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" ""

PLOT
671
411
871
561
R2_Param_2
d
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" ""

PLOT
672
87
872
237
R1_Param_2
d
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" ""

TEXTBOX
60
150
76
170
IF
15
0.0
1

TEXTBOX
57
478
74
498
IF
15
0.0
1

TEXTBOX
911
130
968
150
THEN
15
0.0
1

TEXTBOX
908
454
962
474
THEN
15
0.0
1

PLOT
1135
85
1335
235
R1_Result
s
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"green" 1.0 0 -10899396 true "" ""

PLOT
1135
404
1335
554
R2_Result
s
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"green" 1.0 0 -10899396 true "" ""

CHOOSER
437
274
575
319
type-of-or
type-of-or
"max" "prob-or"
0

CHOOSER
437
328
575
373
type-of-and
type-of-and
"min" "product"
0

CHOOSER
868
294
1006
339
reshaping-method
reshaping-method
"truncate" "prod"
0

TEXTBOX
447
256
574
275
LOGICAL OPERATORS
11
0.0
1

TEXTBOX
880
277
1008
295
RESHAPING METHOD
11
0.0
1

BUTTON
283
282
363
316
once
compute-suitability\ndo-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
885
157
984
202
consistency R1
degree-of-consistency-R1
2
1
11

MONITOR
885
479
982
524
consistency R2
degree-of-consistency-R2
2
1
11

SLIDER
96
94
226
127
r1p1_max
r1p1_max
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
96
128
226
161
r1p1_dev
r1p1_dev
0
100
12.0
1
1
NIL
HORIZONTAL

SLIDER
96
161
226
194
r1p1_min_X
r1p1_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
96
194
226
227
r1p1_max_X
r1p1_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
91
418
223
451
r2p1_max
r2p1_max
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
91
451
223
484
r2p1_dev
r2p1_dev
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
91
485
223
518
r2p1_min_X
r2p1_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
91
520
223
553
r2p1_max_X
r2p1_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
540
91
672
124
r1p2_max
r1p2_max
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
540
125
672
158
r1p2_dev
r1p2_dev
0
100
35.0
1
1
NIL
HORIZONTAL

SLIDER
540
158
672
191
r1p2_min_X
r1p2_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
540
192
672
225
r1p2_max_X
r1p2_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
538
411
670
444
r2p2_max
r2p2_max
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
538
445
670
478
r2p2_dev
r2p2_dev
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
538
479
670
512
r2p2_min_X
r2p2_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
538
513
670
546
r2p2_max_X
r2p2_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
1002
89
1135
122
res1_max
res1_max
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
1002
122
1135
155
res1_dev
res1_dev
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1002
156
1135
189
res1_min_X
res1_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1002
190
1135
223
res1_max_X
res1_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
998
409
1132
442
res2_max
res2_max
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
998
443
1132
476
res2_dev
res2_dev
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
998
476
1132
509
res2_min_X
res2_min_X
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
998
509
1132
542
res2_max_X
res2_max_X
0
100
100.0
1
1
NIL
HORIZONTAL

CHOOSER
435
154
528
199
type-R1
type-R1
"AND" "OR"
0

CHOOSER
436
478
529
523
type-R2
type-R2
"AND" "OR"
1

TEXTBOX
448
127
521
145
AND / OR
14
0.0
1

TEXTBOX
445
454
519
472
AND / OR
14
0.0
1

TEXTBOX
235
40
435
60
Param 1: Density
16
0.0
1

TEXTBOX
678
42
879
62
Param 2: Speed
16
0.0
1

@#$#@#$#@
## WHAT IS IT?

This program illustrates the so-called "Interpolation Method" for systems of fuzzy IF-THEN rules (Klir & Yuan, 1995, section 11.4, pp. 317-321), including fuzzification and defuzzification (Klir & Yuan, 1995, chapter 12). A particular instance of this method is Mamdani inference (also called max-min inference), which is often used in fuzzy control. Another particular instance is max-prod inference.

You can find a detailed explanation of this method in Izquierdo et al. (2015).

## HOW IT WORKS

To understand how the program works, suppose you are searching for a house of certain given characteristics (e.g. 2 bedrooms, garage...) within a radius of 100km from your work. The aim is to calculate the suitability of any particular house given the following 3 rules:

- IF (House is Inexpensive OR Close-to-work), THEN Suitability is Good.
- IF (House is Expensive OR Far-from-work), THEN Suitability is Low.
- IF (House is Averagely-priced AND About-50-km-from-work), THEN Suitability is Regular.

The suitability is calculated using the so-called "Interpolation Method" (Klir & Yuan, 1995, section 11.4, pp. 317-321) and defuzzifying the resulting fuzzy set (Klir & Yuan, 1995, chapter 12). The method consists of the following 4 steps:

1.- Calculate the degree of consistency between the inputs and the antecedent of each IF-THEN rule. The program lets you choose different functions for the logical operators (AND, OR). As an example, consider the first rule at the top row, with antecedent "Inexpensive OR Close-to-work". The computation for crisp inputs price = 110 and distance = 57, using the function Maximum (max) as logical OR, would be:

OR(Inexpensive(110), Close-to-work(57)) = OR(0.45,0.16) = max(0.45,0.16) = 0.45

The result of this step is a number for each rule (i.e. the degree of consistency between the inputs and each rule's antecedent).

2.- Reshape the consequent of each rule given the degree of consistency between the inputs and the rule's antecedent. Possible operators for the reshaping method are truncate (by default) and product (prod). Consider, for example, the rule at the top. The computation would be:

Reshape("Good suitability", 0.45) = truncate("Good suitability", 0.45).

The result of this step is a fuzzy set for each rule.

3.- Aggregate all the reshaped consequents. The result of this step is one fuzzy set (Aggregated Suitability) which is the union of all the reshaped consequents. Possible operators for the aggregation are the Maximum (max), the Probabilistic Sum (prob-or(a,b):=a+b-ab) and the Sum Clipped at 1 (sum).

4.- Defuzzify the aggregated fuzzy set. The defuzzification reduces the aggregated fuzzy set to one single number. Possible defuzzification methods are: Center of Gravity (COG), First of Maxima (FOM), Last of Maxima (LOM), Middle of Maxima (MOM) and Mean of Maxima (MeOM).

If you want to use Mamdani (or max-min) inference, choose min for logical AND, max for logical OR, truncate as Reshaping method, max as Aggregation method, and Center of Gravity (COG) as Defuzzification method.

## HOW TO USE IT

Note that if you press the button "compute suitability changing parameter values in real time" you can see the effect of changing any of the parameter values at runtime.

## NETLOGO FEATURES

This program uses the <b>fuzzy extension</b> for NetLogo, created by Luis R. Izquierdo & Marcos Almendres. The program also makes extensive use of the primitive <b>runresult</b> to allow the user select which procedures to use at runtime.

## LICENCE

fuzzy-system-of-IF-THEN-rules

fuzzy-system-of-IF-THEN-rules is a model designed to show how to implement a system of fuzzy IF-THEN rules in NetLogo.

Copyright (C) 2015 Luis R. Izquierdo, Segismundo S. Izquierdo & Doina Olaru

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

Contact information:
Luis R. Izquierdo
  University of Burgos, Spain.
  e-mail: lrizquierdo@ubu.es

## CREDITS

This program uses the <b>fuzzy extension</b> for NetLogo, created by Luis R. Izquierdo & Marcos Almendres.

## REFERENCES

- Izquierdo, L.R., Olaru, D., Izquierdo, S.S., Purchase, S. & Soutar, G.N. (2015). Fuzzy Logic for Social Simulation using NetLogo. <i>Journal or Artificial Societies and Social Simulation</i>.

- Klir, G.J.& Yuan, B.(1995). <i>Fuzzy Sets and Fuzzy Logic: Theory and Applications.</i> Upper Saddle River, New Jersey: Prentice Hall PTR.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
