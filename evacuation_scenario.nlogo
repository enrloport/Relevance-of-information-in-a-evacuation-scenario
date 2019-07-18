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
  routes
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
      set size size + 1
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
      set route first ( sort-by [[r1 r2] -> route-distance r1 < route-distance r2 ] ([routes] of location) )
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
  report filter [ x -> secure-route? x = 0] routes
end

to-report my-least-bad-route
  report first ( sort-by [ [route1 route2 ] -> secure-route? route1 < secure-route? route2 ] routes )
end
