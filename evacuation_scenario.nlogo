extensions [fuzzy nw csv]

globals [
  aux
  exits
  file
  leaders
  not-leaders
  peacefuls
  violents
  app-killed
  app-rescued
  not-app-killed
  not-app-rescued
  total-killed
  total-rescued

  low-risk
  high-risk
  close-to-me
  far-from-me
  not-in-danger
  in-danger
  degree-of-consistency-R1
  degree-of-consistency-R2
  reshaped-consequent-R1
  reshaped-consequent-R2

  transitable-edges

]

breed [ nodes node ]
breed [ people person ]

nodes-own [
  fire?
  fire-sound?
  attacker?
  attacker-sound?
  bomb?
  bomb-sound?
  corpses?
  scream?
  running-people?
  id
  info
  capacity
  habitable
  hidden-places
  hidden-people
  lock?
  residents
  exits_routes
  rooms_routes
]

links-own [
  dist
  node1
  node2
  sound
  transitable
  visibility
  lockable?
  locked?
  flow
  flow-counter
]

people-own [ ; agentes móviles
  app
  attacker-heard
  attacker-sighted
  fire-heard
  fire-sighted
  bomb-heard
  bomb-sighted
  scream-heard
  corpse-sighted
  running-people
  percived-risk
  destination
  efectivity
  fear
  hidden
  in-a-secure-room
  leader
  leadership
  last-locations
  location
  movility
  next-location
  p-type
  route
  state
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***********************************************************************;;
;;*****************************    SETUP    *****************************;;
;;***********************************************************************;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set app-killed 0
  set app-rescued 0
  set not-app-killed 0
  set not-app-rescued 0
  set exits []

  create-fuzzy-sets

  ;; Create Nodes
  set file (csv:from-file nodes-file ",")
  let cabecera first file
  set file bf file
  foreach file [
    row ->
    create-nodes 1 [
      (foreach cabecera row [
        [c r] ->
        run (word "set " c " " r)
      ])
      if (id - floor id) < 0.099 [ set exits (sentence exits (floor id)) ]
      set color blue
      set habitable 1
      ;set label id
      set shape "circle"
      ;set size 0.3
      ;set size size + 1
      set residents 0
      set hidden-people 0
      set xcor xcor * 1.1
      set ycor ycor * 1.1
    ]
  ]


  ;; Create Edges
  set file (csv:from-file edges-file ",")
  set cabecera first file
  set file bf file
  foreach file [
    row ->
    ask one-of nodes with [id = item 0 row] [
      create-link-with one-of nodes with [id = read-from-string (item 1 row)] [
        set node1 item 0 row
        set node2 read-from-string (item 1 row)
        set dist read-from-string (item 2 row)
        set visibility read-from-string (item 3 row)
        set sound read-from-string (item 4 row)
        set transitable read-from-string (item 5 row)
        set lockable? read-from-string (item 6 row)
        set flow read-from-string (item 7 row)
        if transitable = 0 [ set hidden? true ]
      ]
    ]
  ]
  set transitable-edges (link-set links with [transitable > 0] )

  ; Create People
  create-people num-peacefuls [

    set shape "person"
    set p-type "peaceful"
    set state "not-alerted"
    set hidden false

    set attacker-sighted 0
    set fire-sighted 0
    set bomb-sighted 0
    set attacker-heard 0
    set fire-heard 0
    set bomb-heard 0
    set fear 0
    set percived-risk 0
    set in-a-secure-room false

    ifelse random-float 1 < app-percentage / 100 [ set app true ][ set app false ]

    ifelse random-float 1 < leaders-percentage[
      set leadership (random-float 1) + 0.1
      set color yellow
    ][
      set leadership 0
      set color white]
    set leader nobody

    set aux one-of nodes with [residents < capacity]
    ;set aux one-of nodes with [id = 6.1]
    set location aux
    ask aux [set residents residents + 1 ]
    set last-locations (list location location location location)
    set next-location location
    set route []
    move-to location
  ]


  create-people num-violents [
    set shape "person"
    set color red
    set p-type "violent"

    set location one-of nodes ;with [id = 6.6]
    set last-locations (list location location location location)
    set destination location
    set efectivity attackers-efectivity
    move-to location
  ]

  set violents turtle-set (people with [p-type = "violent"] )
  set peacefuls turtle-set (people with [p-type = "peaceful"])
  set leaders turtle-set (people with [leadership > 0])
  set not-leaders turtle-set (peacefuls with [leadership = 0])

  reset-ticks
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***********************************************************************;;
;;****************************     TO GO     ****************************;;
;;***********************************************************************;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to go

  ; STOP conditions
  if (num-peacefuls = app-killed + app-rescued + not-app-killed + not-app-rescued) or (max-iter > 0 and ticks = max-iter) [stop]

  update-world

  ask violents [
    let loc location
    ifelse any? peacefuls with [location = loc and not hidden][attack][move-attacker]
  ]
  ask leaders [
    set label hidden

    ifelse [id - floor id] of location < 0.099 [
      ifelse app [set app-rescued app-rescued + 1][set not-app-rescued not-app-rescued + 1]
      die
    ][
      peaceful-believe

      peaceful-desire fire-sighted fire-heard attacker-sighted attacker-heard bomb-sighted
      bomb-heard scream-heard running-people percived-risk fear

      peaceful-intention
      if fear > 0 [set fear fear - 1]
    ]
  ]

  ask not-leaders [

    ifelse [id - floor id] of location < 0.099 [
      ifelse app [set app-rescued app-rescued + 1][set not-app-rescued not-app-rescued + 1]
      die
    ][
      let loc-aux location
      ifelse any? leaders with [location = loc-aux] [
        if hidden [
          set hidden false
          ask location [set hidden-people hidden-people - 1]
        ]
        set leader ( max-one-of leaders with [location = [location] of myself ] [leadership] )
        set percived-risk [percived-risk] of leader
        set state ["with-leader"]
      ][
        peaceful-believe

        peaceful-desire fire-sighted fire-heard attacker-sighted attacker-heard bomb-sighted
        bomb-heard scream-heard running-people percived-risk fear

      ]
      peaceful-intention
      if fear > 0 [set fear fear - 1]
    ]
  ]


  tick
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***********************************************************************;;
;;****************************   PEACEFULS   ****************************;;
;;***********************************************************************;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   BDI FUNCTIONS  ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to peaceful-believe
  ;let loc-aux location
  ;  let le-aux leadership

  set attacker-sighted [attacker?] of location
  set fire-sighted [fire?] of location
  set bomb-sighted [bomb?] of location
  set attacker-heard [attacker-sound?] of location
  set fire-heard [fire-sound?] of location
  set bomb-heard [bomb-sound?] of location
  set scream-heard [scream?] of location
  set corpse-sighted [corpses?] of location
  set running-people [running-people?] of location

  let percived-signals (attacker-sighted + fire-sighted + bomb-sighted + attacker-heard
    + fire-heard + bomb-heard + scream-heard + corpse-sighted + running-people)
  if percived-signals > 1 [set percived-signals 1]

  if app-info? and app and app-killed + not-app-killed > 0 [set percived-signals 1]


  let dis-aux 0
  if percived-signals > 0 [
    ifelse running-people > 0 [
      ask location[
        set dis-aux 10
      ]
    ][
      let nearest-dangerous-node min-one-of nodes with [habitable < 1] [distance myself]
      set dis-aux distance nearest-dangerous-node
    ]

    compute-danger (dis-aux) (percived-signals * 100)

    if degree-of-consistency-R2 > degree-of-consistency-R1 and degree-of-consistency-R2 > percived-risk[
      set fear fear + 2
      set percived-risk degree-of-consistency-R2
    ]
  ]

end


to peaceful-desire [#fire-sighted #fire-heard #attacker-sighted  #attacker-heard #bomb-sighted #bomb-heard #scream-heard #running-people #percived-risk #fear]
  ifelse any? leaders with [location = [location] of myself] [
    set state "with-leader"
  ][

    ifelse app-info? and app [
      set aux app-recomendations
      ifelse aux = 0 [
        ifelse (  ([lock?] of location) = 1 and ( not violents-in-my-room ) ) or ([hidden-places - hidden-people] of location > 0) [
          set state "hidden"
        ][
          set state "running-away" ; there is no place to hide, so, run away
        ]
      ][
        set state "running-away"
      ]
    ][
      if not in-secure-room? and percived-risk > 0 [
        ifelse (distance (min-one-of violents [distance myself])) < 5 and ([hidden-places - hidden-people] of location)  > 0  [
          set state "hidden"
        ][
          set state "running-away"
        ]
      ]
    ]
  ]

end


to peaceful-intention
  ifelse state = "not-alerted"        [keep-working][
    ifelse state = "with-leader"      [follow-leader][
      ifelse (state = "running-away") [run-away][
        ifelse (state = "hidden")     [hide][
          if     (state = "fighting") [fight]
        ]
      ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;   STATES FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; huyendo:             running away
; escondido:           hidden
; luchando:            fighting
; evacuado:            evacuated
; desconocedor:        not-alerted
; siguiendo a lider:   follow-leader


to follow-leader
  set color 49

  ifelse leader != nobody [
    ;set location [location] of leader
    set next-location [next-location] of leader
    face next-location
    ;fd 0.4
    if location != next-location [
      ask (link ([who] of location) ([who] of next-location) ) [
        if flow-counter >= 0 [
          set flow-counter flow-counter - 1
          ask myself [fd .4]
        ]
      ]
    ]
  ][
    run-away
  ]
end

to run-away
  if leadership = 0 [set color green]
  if hidden [
    set hidden false
    ask location [set hidden-people hidden-people - 1]
    if app-info? and app [
      set route first ( sort-by [[r1 r2] -> route-distance r1 < route-distance r2 ] ([exits_routes] of location) )
      ask location [
        if lock? = 1 [ ask my-links with [lockable? > 0][set locked? 0] ] ; If there is a locked lock, then unlock it
      ]
    ]
  ]
  ask location [set running-people? running-people? + 0.3]
  ifelse app-info? and app or leadership > 0 [
    follow-route route
  ][
    if location = next-location [search-intuitive-node]
    advance
  ]
end

to hide
  if hidden = false[
    set color grey
    set hidden true
    if leadership = 0 [set color grey]
    ask location [set hidden-people hidden-people + 1]
    if [lock? = 1] of location  and (not violents-in-my-room) [
      set color white
      ask location [
        ask my-links with [lockable? > 0] [
          if locked? = 0 [
            set transitable 0
            set locked? 1
          ]
        ]
      ]
    ]
  ]
end

to fight
  set color black
  if hidden [
    set hidden false
    ask location [set hidden-people hidden-people - 1]
  ]
  if leadership = 0 [set color black]
  set aux random-float 1
  if aux < efectivity [
    set aux location
    ask one-of violents with [location = aux] [die]
  ]
end


to keep-working
  if any? peacefuls with [location = [location] of myself and state = "running-away" ] [set state "running-away"]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   CHECK FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-secure-room?
  if [lock?] of location = 0 or any? ([my-links] of location) with [lockable? = 1 and locked? = 0] [
    report false
  ]
  report true
end

to-report violents-in-my-room
  let loc-aux ( [floor id] of location)
  ifelse any? violents with [ [floor id] of location = loc-aux ][
    report true
  ][
    report false
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   ACTION FUNCTIONS  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to follow-route [#route]
  let loc-aux ([id] of location)

  ifelse empty? #route or not (member? loc-aux #route) [
    ifelse not empty? [my-secure-routes] of location [
      set route [my-shortest-route my-secure-routes] of location
    ][
      set route [my-least-bad-route] of location
    ]
  ][
    ifelse location != next-location [
      ifelse [capacity <= residents] of next-location [
        set next-location location
      ][
        advance
      ]

    ][
      let pos-aux (position loc-aux #route)
      set next-location one-of nodes with [ id = ( item (pos-aux + 1) #route) ]
      face next-location
    ]
  ]
end

to advance ; go to next-node
  ifelse distance next-location < 0.7 [ ; Avanzamos hasta alcanzar el siguiente nodo
    set location next-location
    set last-locations (sentence (bf last-locations) location)
  ][
    ask (link ([who] of location) ([who] of next-location) ) [
      if flow-counter >= 0 [
        set flow-counter flow-counter - 1
        ask myself [fd .4]
      ]
    ]
  ]
end


to search-intuitive-node
  let destinations []
  ask location [
    ask my-links with [transitable > 0] [
      if [capacity - residents] of other-end > 0 [
        set destinations (sentence destinations other-end)
      ]
    ]
  ]

  if not empty? destinations [

    set destinations turtle-set destinations

    let secure-destinations (destinations with [not any? people-here with [p-type = "violent"]])
    if any? secure-destinations [set destinations secure-destinations]

    ifelse any? destinations with[ (id - floor id)< 0.02] [ ; The agent has found an exit
        set next-location one-of destinations with [ (id - floor id)< 0.02]
    ][
      ; Ha encontrado una sala con salida
      ifelse any? destinations with[ member? (floor id) exits and (not any? people-here with [p-type = "violent"]) ] [
        set next-location one-of destinations with [ member? (floor id) exits ]
      ][
        set aux (last-locations)

        ifelse any? destinations with[ not (member? who aux)  ] [
          set next-location one-of destinations with[ not (member? who aux)]
        ][
          set next-location one-of destinations
        ]
      ]
    ]
    face next-location
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   FUZZY FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-fuzzy-sets

  set low-risk        fuzzy:gaussian-set [0   20 [0 100]]
  set high-risk       fuzzy:gaussian-set [100 10 [0 100]]

  set close-to-me     fuzzy:gaussian-set [0   10 [0 100]]
  set far-from-me     fuzzy:gaussian-set [100 10 [0 100]]

  set not-in-danger   fuzzy:gaussian-set [10 2 [0 10]]
  set in-danger       fuzzy:gaussian-set [0  2 [0 10]]
end



to compute-danger [#dist #risk-level]

  ;; COMPUTATION OF DEGREES OF CONSISTENCY BETWEEN FACTS (INPUTS) AND ANTECEDENTS FOR EACH RULE

  ;; Rule 1: IF (low risk OR far from me)...
  let degree-of-consistency-R1a fuzzy:evaluation-of low-risk #risk-level
  let degree-of-consistency-R1b fuzzy:evaluation-of far-from-me #dist
  set degree-of-consistency-R1 (runresult (word "max" " list degree-of-consistency-R1a degree-of-consistency-R1b"))

  ;; Rule 2: IF (High Risk OR Close to me)...
  let degree-of-consistency-R2a fuzzy:evaluation-of high-risk #risk-level
  let degree-of-consistency-R2b fuzzy:evaluation-of close-to-me #dist
  set degree-of-consistency-R2 (runresult (word "max" " list degree-of-consistency-R2a degree-of-consistency-R2b"))

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                       ;;
;;*****************************  ATTACKERS  *****************************;;
;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to move-attacker
  ifelse location = destination [
    set last-locations (sentence (bf last-locations) location)
    attacker-destination
  ][
    set aux ([id] of destination)
    let aux2 [id] of location
    ; if the door is locked, the violent backs to his location
    ifelse ([transitable] of link ([who] of location) ([who] of destination)) = 0 [
      set destination location
    ][
      ifelse distance destination < 0.5 [
        set location destination
      ][
        face destination
        fd 0.4
      ]
    ]
  ]
end

to attack
  let l location
  if random-float 1 < efectivity [
    if any? people with [location = l and hidden = false and p-type = "peaceful"][
      ask one-of people with [location = l and hidden = false and p-type = "peaceful"][
        ifelse app [set app-killed app-killed + 1] [set not-app-killed not-app-killed + 1]
        die
        ask location [set corpses? corpses? + 0.2]
        ask location [
          ask my-links with [sound > 0] [
            ask other-end [set scream? 1 * ([sound] of myself )]
          ]
        ]
      ]
    ]
  ]
end

to attacker-destination
  let destinations []
  ask location [ set destinations ( sentence destinations ( [other-end] of my-links with [transitable > 0] ) ) ]
  set destinations ( filter [ x -> not member? x last-locations] destinations)
  ifelse empty? destinations [
    set destination one-of ( [[other-end] of my-links with [transitable > 0]] of location )
  ][
    set destination max-one-of (turtle-set destinations) [residents]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                       ;;
;;*******************************  WORLD  *******************************;;
;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;Changes the habitable atribute in nodes and transitable atribute in links depending on danger location
to update-world
  ask nodes [
    set habitable 1
    set fire? 0
    set attacker? 0
    set bomb? 0

    set attacker-sound? 0
    set fire-sound? 0
    set bomb-sound? 0
    set scream? 0

    set residents ( (count people with [location = myself and hidden = false and p-type = "peaceful" ]) )
  ]

  ask people [set label ""]

  ask transitable-edges[
    let n1 end1
    let n2 end2
    ifelse any? people with [location = n1 and next-location = n2 or location = n2 and next-location = n1 ] [
      set flow-counter (flow-counter + flow)
    ][
      set flow-counter 0
    ]
  ]
  ask violents [
    let efct-aux efectivity

    ask location [
      set habitable 1 - efct-aux
      set attacker? efct-aux

      ask my-links [
        let visib-aux visibility
        let sound-aux sound
        let dist-aux dist
        if visibility > 0 [
          ask other-end [
            set attacker? (attacker? + (visib-aux * efct-aux) )
            if attacker? > 1 [ set attacker? 1]
          ]
        ]
      ]
    ]
  ]
end

to-report app-recomendations
  ifelse hidden [
    ifelse distance (min-one-of violents [distance myself]) > 10 [
      report 1
    ][
      report 0
    ]
  ][
    report 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                       ;;
;;*******************************  NODES  *******************************;;
;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report my-shortest-route [#routes]
  let minim (item 0 #routes)
  foreach #routes [ x ->
    if length x < length minim[set minim x]
  ]
  report minim
end

to-report route-distance [#route]
  let dist-aux 0
  foreach #route [ x ->
    set dist-aux dist-aux + 1
  ]
  report dist-aux
end

to-report secure-route? [#route]
  let sum-aux 0
  foreach #route [ x ->
    if ([habitable] of one-of nodes with [id = x]) < 1 [ set sum-aux sum-aux + 1]
  ]
  report sum-aux
end

to-report my-secure-routes
  report filter [ x -> secure-route? x = 0] exits_routes
end

to-report my-least-bad-route
  report first ( sort-by [ [route1 route2 ] -> secure-route? route1 < secure-route? route2 ] exits_routes )
end
@#$#@#$#@
GRAPHICS-WINDOW
336
8
1137
290
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
60
0
20
0
0
1
ticks
30.0

BUTTON
210
57
265
92
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
210
195
243
num-peacefuls
num-peacefuls
1
300
300.0
1
1
NIL
HORIZONTAL

SLIDER
10
352
194
385
num-violents
num-violents
0
10
1.0
1
1
NIL
HORIZONTAL

BUTTON
269
57
324
94
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
334
380
432
425
NIL
not-app-rescued
17
1
11

MONITOR
437
380
534
425
NIL
not-app-killed
17
1
11

SLIDER
10
251
194
284
leaders-percentage
leaders-percentage
0.0
1.0
0.0
0.05
1
NIL
HORIZONTAL

MONITOR
334
330
432
375
NIL
app-rescued
17
1
11

MONITOR
437
330
534
375
NIL
app-killed
17
1
11

SLIDER
10
392
195
425
attackers-efectivity
attackers-efectivity
0
1
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
7
143
192
176
max-iter
max-iter
0
5000
0.0
5
1
NIL
HORIZONTAL

SWITCH
210
352
321
385
shooting?
shooting?
1
1
-1000

SWITCH
210
15
322
48
app-info?
app-info?
0
1
-1000

BUTTON
269
98
324
133
once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
289
195
322
app-percentage
app-percentage
0
100
50.0
1
1
NIL
HORIZONTAL

INPUTBOX
8
13
196
75
nodes-file
hole.csv
1
0
String

INPUTBOX
9
76
196
138
edges-file
edges.csv
1
0
String

MONITOR
551
330
649
375
total-rescued
app-rescued + not-app-rescued
17
1
11

MONITOR
551
379
648
424
total-killed
app-killed + not-app-killed
17
1
11

MONITOR
207
297
271
342
leaders
count leaders
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
