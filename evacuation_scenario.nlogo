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
  app-accident
  not-app-accident
  total-killed
  total-rescued
  violents-killed

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

  t-agent
  transitable-edges
  speed
  not-alerted-app
  not-alerted-not-app
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
  lock?
  leaders?
  police?
  id
  info
  capacity
  habitable
  accident-prob
  hidden-places
  hidden-people
  residents
  exits_routes
  rooms_routes
  reacheables
  visibles
  nearest-danger
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

people-own [
  app
  attacker-heard
  attacker-sighted
  fire-heard
  fire-sighted
  bomb-heard
  bomb-sighted
  scream-heard
  corpse-sighted
  police-sighted
  leader-sighted
  running-people
  percived-risk
  destination
  efectivity
  detected
  fear
  sensibility
  hidden
  leadership
  last-locations
  location
  movility
  next-location
  p-type
  route
  state
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;*****************************************  TO SETUP  ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set app-killed 0
  set app-rescued 0
  set app-accident 0
  set not-app-killed 0
  set not-app-rescued 0
  set not-app-accident 0
  set violents-killed 0
  set exits []
  set speed mean-speed

  create-fuzzy-sets

  ;; CREATE NODES
  set file (csv:from-file "nodes_NL.csv" ",")
  let cabecera first file
  set file bf file
  foreach file [
    row ->
    create-nodes 1 [
      (foreach cabecera row [
        [c r] ->
        run (word "set " c " " r)
      ])
      if (id - floor id) < 0.099 [ set exits (sentence exits (floor id) ) ]
      set color blue
      set habitable 1
      set shape "circle"
      set residents 0
      set hidden-people 0
      set xcor xcor * 1
      set ycor ycor * 1
    ]
  ]

  ;; CREATE EDGES
  set file (csv:from-file "edges_NL.csv" ",")
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

  ask nodes [
    let r-aux reacheables
    set reacheables nodes with[ member? id r-aux ]
    set visibles turtle-set ( [other-end] of my-links with [visibility > 0] )
  ]

  ;; CREATE PECEFULS
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
    set sensibility ( 0.9 + random-float 0.2 ) ; Between 0.9 and 1.1. This parameter determines the level in which the signals affects to the fear
    set percived-risk 0
    set movility not-alerted-speed
    set leader-sighted nobody
    set location one-of nodes with [residents < capacity]
    ask location [set residents residents + 1 ]
;    set last-locations (list nobody nobody nobody nobody)
    set last-locations []
    set next-location location
    set route []

    ifelse random-float 1 < app-percentage / 100 [ set app true ][ set app false ]

    ifelse random-float 1 < leaders-percentage[
      set leadership (random-float 1) + 0.1
      set route ([my-shortest-route exits_routes] of location)
      set color yellow
    ][
      set leadership 0
      set color white
    ]
    move-to location
  ]

  if target-agent >= 0 [
    set t-agent (count nodes + target-agent) ; The agent 0 will be created with who = (0 + number of nodes), so we need to adjust this
    ask person t-agent [set size 2]
  ]

  ;; CREATE VIOLENTS
  create-people num-violents [
    set shape "person"
    set detected 0
    set color 17
    set p-type "violent"
    set movility attackers-speed
    set location one-of nodes
    set last-locations (list nobody nobody location location)
    set destination location
    set route []
    set efectivity attackers-efectivity
    move-to location
  ]

  ;; CREATE TURTLE SETS
  set violents    turtle-set (people with [p-type = "violent"] )
  set peacefuls   turtle-set (people with [p-type = "peaceful"])
  set leaders     turtle-set (people with [leadership > 0])
  set not-leaders turtle-set (peacefuls with [leadership = 0])

  set not-alerted-app count people with [state = "not-alerted" and app]
  set not-alerted-not-app count people with [state = "not-alerted" and (not app)]

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;****************************************    TO GO    ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  set not-alerted-app count people with [state = "not-alerted" and app]
  set not-alerted-not-app count people with [state = "not-alerted" and (not app)]

  ;; STOP conditions
  if (count peacefuls = 0) or (max-iter > 0 and ticks = max-iter) [stop]

  update-world

  ; A label for the targets
  if target-node > -1 [ ask node target-node [set label "T"] ]

  if target-agent > -1 [
    set t-agent (count nodes + target-agent)
    ifelse person t-agent != nobody [ ask person t-agent [set size 2] ][ set target-agent -1 ]
  ]
  ask violents [
    violents-belive
    violents-desire
    violents-intention
  ]
  ask peacefuls [
    let loc-aux location
    ifelse leadership = 0 and any? leaders with [ location = loc-aux and state = "running-away"] [
      set leader-sighted ( max-one-of leaders with [location = loc-aux] [leadership] )
      set percived-risk [percived-risk] of leader-sighted
      set state "with-leader"
    ][
      peaceful-believe
      peaceful-desire
    ]
    peaceful-intention
    if fear > 0 [set fear fear - 1]
    casualty?
  ]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;****************************************  ATTACKERS  ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   BDI  VIOLENTS  ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to violents-belive
  set police-sighted police-sighted + ([police?] of location)
end

to violents-desire
  (ifelse
    police-sighted > 0 [set state "avoiding-police"]
    target-node >= 0 or ( target-agent >= 0 and person t-agent != nobody ) [set state "finding-target"]
    [set state "aggressive-behaviour"]
  )
end

to violents-intention
  (ifelse
    state = "avoiding-police"      [avoid-police]
    state = "finding-target"       [find-target]
    state = "aggressive-behaviour" [be-aggressive]
  )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;   STATES FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to avoid-police
  set label "ap"
end

to be-aggressive
  set label "ba"
  let loc location
  ifelse shooting?[
    set aux [visibles] of location
    ifelse any? peacefuls with [ member? location aux ] [
      shoot aux
    ][
      if location = destination [attacker-destination]
      violent-advance
    ]
  ][
    ifelse any? peacefuls with [location = loc and not hidden][
      attack
    ][
      if location = destination [attacker-destination]
      violent-advance
    ]
  ]
end

to find-target
  set label "ft"
  set aux location

  ; The attacker will search for the target agent first
  ifelse target-agent >= 0 and person t-agent != nobody [
    ifelse aux = [location] of person t-agent [
      ifelse shooting? [shoot (list location) ][attack]

      set route []
    ][
      ifelse empty? route [
        set route ( bfs ([who] of aux) ([who] of ([location] of person t-agent)) )
        follow-route2
      ][
        follow-route2
      ]
    ]
  ][
    if target-node >= 0[
      ifelse [who] of location = target-node [
        ifelse shooting? [shoot [visibles] of location][attack]
        if [residents] of location = 1 [set target-node -1]
      ][
        if empty? route [ set route ( bfs ([who] of aux) target-node ) ]
        follow-route2
      ]
    ]
  ]
end

to follow-route2 ; This function works with the "who" property of the nodes
  ifelse location = destination [
    ifelse [who] of location = last route [
      set route []
    ][
      let loc-aux ([who] of location)
      let pos-aux (position loc-aux route)
      set destination node ( item (pos-aux + 1) route)
      face destination
    ]
  ][
    violent-advance
  ]
end

to violent-advance
  ifelse distance destination < 0.5 [ ; The agent has reached next-location
    ask location [set residents residents - 1]
    set location destination
    ask location [set residents residents + 1]
    if not member? location last-locations [set last-locations (lput location last-locations)]
  ][
    ask (link ([who] of location) ([who] of destination) ) [
      if flow-counter >= 1 [
        ask myself [
          if [capacity > residents] of destination [
            face destination
            set aux distance destination
            ifelse movility > aux [fd aux][fd movility]
          ]
        ]
        set flow-counter flow-counter - 1
      ]
    ]
  ]
end

to attack
  set detected 1
  set color red
  ask location [set habitable 0]
  let l location
  if random-float 1 < efectivity [
    if any? people with [location = l and hidden = false and p-type = "peaceful"][
      ask one-of people with [location = l and hidden = false and p-type = "peaceful"][ died-agent "attack" ]
    ]
  ]
end

to shoot [#visibles]
  if any? peacefuls with [member? location #visibles][
    set detected 1
    set color red
    ask location [
      set habitable 0
      set attacker-sound? attacker-sound? + 0.5
      ask my-links with [sound > 0] [
        let s-aux sound
        ask other-end [set attacker-sound? attacker-sound? + 0.5 * s-aux]
      ]
    ]
    ask one-of peacefuls with [member? location #visibles][ died-agent "shoot" ]
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




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;****************************************  PEACEFULS  ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   BDI PEACEFULS  ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to peaceful-believe
  set attacker-sighted attacker-sighted + [attacker?] of location
  set fire-sighted fire-sighted + [fire?] of location
  set bomb-sighted bomb-sighted + [bomb?] of location
  set attacker-heard attacker-heard + [attacker-sound?] of location
  set fire-heard fire-heard + [fire-sound?] of location
  set bomb-heard bomb-heard + [bomb-sound?] of location
  set scream-heard scream-heard + [scream?] of location
  set corpse-sighted corpse-sighted + [corpses?] of location
  set running-people running-people + [running-people?] of location

  let percived-signals 0
  ifelse app-info? and app and app-trigger [
    set percived-signals 1
  ][
    set percived-signals (attacker-sighted + fire-sighted + bomb-sighted + attacker-heard
    + fire-heard + bomb-heard + scream-heard + corpse-sighted + running-people)
    if percived-signals > 1 [set percived-signals 1]
  ]

  let dis-aux 0
  if percived-signals > 0 [
    if movility = not-alerted-speed [ set movility ( speed - (max-speed-deviation) + random-float (2 * max-speed-deviation) ) ]

    ifelse any? ([visibles] of location) with [all-my-signals > 0] [
      let near-signal max-one-of ([visibles] of location) [all-my-signals]
      set dis-aux ( [dist] of ( link ([who] of location) ([who] of near-signal ) ) )
    ][
      set dis-aux 15
    ]

    compute-danger (dis-aux) (percived-signals * 100)

    if degree-of-consistency-R2 > degree-of-consistency-R1 and degree-of-consistency-R2 > percived-risk[
      set fear fear + 2
      set percived-risk degree-of-consistency-R2
    ]
  ]
end

to peaceful-desire
  ifelse app-info? and app and app-trigger and route = [] [  ; The app is giving information to the agent.
    set state "asking-app"
  ][
    ; Not App beahaviour
    if not in-secure-room? and percived-risk > 0 [
      set aux location
      ifelse any? violents with[ member? location ([reacheables] of aux) ] and ([hidden-places - hidden-people] of location)  > 0  [
        set state "hidden"
      ][
        ifelse any? violents with [aux = location] and ([residents] of location) > ( 11 * count (violents with [aux = location]) )
        [set state "fighting"]
        [set state "running-away"]
      ]
    ]
  ]
end

to peaceful-intention
  ifelse [ id - (floor id) ] of location < 0.099 and state != "not-alerted" [ ; if the agent has been alerted and has reached an exit, evacuate it
    ifelse app [set app-rescued app-rescued + 1][set not-app-rescued not-app-rescued + 1]
    ask location [set residents residents - 1]
    die
  ][
    (ifelse
      state = "not-alerted"     [keep-working]
      state = "with-leader"     [follow-leader]
      state = "running-away"    [run-away]
      state = "hidden"          [hide]
      state = "fighting"        [fight]
      state = "asking-app"      [ask-app]
      state = "following-route" [follow-route route])

    if leadership = 0 [
      (ifelse
        state = "with-leader"     [set color 48]
        state = "running-away"    [set color green]
        state = "hidden"          [set color grey]
        state = "fighting"        [set color black]
        state = "asking-app"      [set color white]
        state = "following-route" [set color 57])
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;   STATES FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to ask-app
  (ifelse
    app-recomendations = 0 [ ; The app will recomend to hide somewhere, but is not giving a route to the agent
      set route []
      ifelse (([lock?] of location) = 1 and (not violents-in-my-room)) or ([hidden-places - hidden-people] of location > 0)[
        set state "hidden"
      ][
        set state "running-away"
      ]
    ]
    app-recomendations = 1 [ ; The app gives to the agent a path to a secure-room
      set route secure-room-path
      set state "following-route"
    ]
    app-recomendations = 2 [ ; The app gives to the agent a path to evacuate
      set route exit-path
      set state "following-route"
  ])
end

to follow-leader
  ifelse any? ([visibles] of location) with [ id - floor id < 0.099 ] [
    set route ( [my-shortest-route exits_routes] of location )
    follow-route route
  ][
    ifelse leader-sighted != nobody [
      ifelse ( [location] of leader-sighted = location)[
        set next-location [next-location] of leader-sighted
      ][
        set next-location [location] of leader-sighted
      ]
      advance
    ][
      set state "running-away"
      run-away
    ]
  ]
end

to run-away
  stop-hidden
  ifelse leadership > 0 [
    follow-route route
  ][
    if location = next-location or [residents] of next-location = [capacity] of next-location [search-intuitive-node]
    advance
  ]
end

to hide
  if hidden = false[
    set hidden true
    ifelse [lock? = 1] of location  and (not violents-near) [
      if leadership = 0 [set color pink]
      ask location [
        ask my-links with [lockable? > 0] [
          if locked? = 0 [
            set transitable 0
            set locked? 1
          ]
        ]
      ]
    ][
      ask location [set hidden-people hidden-people + 1]
    ]
  ]
end

to fight
  stop-hidden
  if random-float 1 < 0.1 [
    set aux location
    ask one-of violents with [location = aux] [
      set violents-killed violents-killed + 1
      die
    ]
  ]
end

to keep-working
  if random-float 1 < 0.007 or distance location >= movility[
    if location = next-location [ set next-location (one-of ([reacheables] of location)) ]
    advance
  ]
end

to stop-hidden
  if hidden [
    set hidden false
    ifelse in-secure-room? [
      ask location [
        ask my-links with [lockable? > 0] [
          if locked? = 1 [
            set transitable 1
            set locked? 0
          ]
        ]
      ]
    ][
      ask location [set hidden-people hidden-people - 1]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   CHECK FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-secure-room?
  if [lock?] of location = 0
  or all? ([my-links] of location) [lockable? = 0]
  or any? ([my-links] of location) with [lockable? = 1 and locked? = 0]
  [report false]
  report true
end

to-report violents-in-my-room
  let loc-aux ( [floor id] of location)
  ifelse any? violents with [ [floor id] of location = loc-aux ] [report true] [report false]
end

to-report violents-near
  let neighs ([reacheables] of location)
  ifelse any? violents with [ member? location neighs ] [report true] [report false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   ACTION FUNCTIONS  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to follow-route [#route] ; This function works with the "id" property of the nodes
  let loc-aux ([id] of location)
  if not member? loc-aux #route [
    if any? ([reacheables] of location) with [member? id #route] [set route (fput ([id] of location) #route)]
  ]
  if not empty? #route and (member? loc-aux #route) [
    ifelse location != next-location [
      advance
    ][
      ifelse [id] of location = last #route [ ; The agent has completed the route
        set state "hidden"
      ][
        let pos-aux (position loc-aux #route)
        set next-location one-of nodes with [ id = ( item (pos-aux + 1) #route) ]
        face next-location
      ]
    ]
  ]
end



to advance ; Go to next-node
  ifelse distance next-location < 0.6 [ ; The agent has reached next-location
    ask location [set residents residents - 1]
    set location next-location
    ask location [set residents residents + 1]
    ;if not member? location last-locations [ set last-locations (lput location last-locations) ]
    ifelse member? location last-locations [
      set last-locations ( lput location (remove location last-locations) )
    ][
      set last-locations (lput location last-locations)
    ]
  ][
    if location != next-location [
      update-running-people
      update-flow
    ]
  ]
end

to update-running-people
  if percived-risk > 0 [
    ask next-location [ set running-people? running-people? + 0.05]
    ask location[
      set running-people? running-people? + 0.05
      ask my-links with [visibility > 0 ][
        let visib-aux visibility
        ask other-end [set running-people? (running-people? + 0.02) * visib-aux ]
      ]
    ]
  ]
end

to update-flow
  ifelse (link ([who] of location) ([who] of next-location) ) = nobody[
    search-intuitive-node
  ][
    ask (link ([who] of location) ([who] of next-location) ) [
      if flow-counter >= 1 [
        ask myself [
          if [capacity > residents] of next-location [
            face next-location
            set aux distance next-location
            ifelse movility > aux [fd aux][fd movility]
          ]
        ]
        set flow-counter flow-counter - 1
      ]
    ]
  ]
end


to search-intuitive-node
  let destinations ([reacheables] of location)
  let secure-destinations (destinations with [not any? people-here with [p-type = "violent"]])

  if any? secure-destinations [set destinations secure-destinations]

  ifelse any? ([visibles] of location) with[ (id - floor id)< 0.099] [ ; The agent has sighted an exit
    follow-route ( [my-shortest-route exits_routes] of location )
  ][
    let ll last-locations
    ifelse any? destinations with[ not (member? who ll)  ] [
      set next-location one-of destinations with[ not (member? who ll)]
    ][
      foreach last-locations [
        x ->
        ask x [
          if member? x ll [
            set next-location x
            stop
          ]
        ]
      ]
    ]
  ]
  face next-location
end

to casualty?
  let pos ( floor ([residents] of location) / 5 )
  if pos > 9 [set pos 9]
  if random-float 1 < ( item pos ([accident-prob] of location) ) * movility * 0.01 [ ;; 0.01 to adjust de values
    died-agent "casualty"
  ]
end

to died-agent [#cause]
  ask location [
    set corpses? corpses? + 0.2
    set residents residents - 1
  ]
  (ifelse
    #cause = "casualty" [
      ifelse app [set app-accident app-accident + 1] [set not-app-accident not-app-accident + 1]
      die
    ]
    #cause = "attack"   [
      ifelse app [set app-killed app-killed + 1] [set not-app-killed not-app-killed + 1]
      ask location [ ask my-links with [sound > 0] [ask other-end [set scream? 0.5 * ([sound] of myself )]] ]
      die
    ]
    #cause = "shoot"    [
      ifelse app [set app-killed app-killed + 1] [set not-app-killed not-app-killed + 1]
      die
    ])
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;*****************************************  POLICE  ******************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TO DO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;******************************************  WORLD  ******************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; It changes the habitable atribute in nodes depending on danger location, also updates the counter-flow in edges
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
    set running-people? 0
    ;; TO DO: si app? -> actualiza la distancia al peligro de las salidas o que sean los violentos los que
    ;; actualicen estos valores (nodos con atributo nearest-danger)
    ;; hacer que la aplicacion recomiende esconderse sólo al número de agentes que quepan en el nodo
    ;; y evacuar al resto de agentes.
  ]
  ask transitable-edges[
    ifelse flow-counter < 1 [
      set flow-counter flow-counter + flow
    ][
      set flow-counter flow
    ]
  ]
  ask violents [
    if detected > 0 [
      let efct-aux efectivity
      ask location [
        set habitable 1 - efct-aux ;; aqui la distancia
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
  ]
end

to-report app-trigger
  if first-blood and app-killed + not-app-killed > 0 [report true]
  ;; For the crowd-running trigger we have a few options:
  ;; 1) Count people with state running-away or with-leader
  ;; 2) Count people with speed > not-alerted-speed
  ;; 3) Ask for any link with a diference between flow and flow-counter
  if crowd-running and (count people with [movility > not-alerted-speed]) > 5 [report true]
  report false
end

to-report app-recomendations
  ;; TO DO: la lógica de la app. Mientras haya donde esconderse, recomendar sala, si no, salida más cercana
  report 2
end

to-report secure-room-path
  report ( [my-shortest-route rooms_routes] of location )
end
to-report exit-path
  report ( [my-shortest-route exits_routes] of location )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;******************************************  NODES  ******************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report my-shortest-route [#routes]
  let minim (item 0 #routes)
  foreach #routes [ x -> if length x < length minim[set minim x] ]
  report minim
end

to-report route-distance [#route]
  let dist-aux 0
  foreach #route [ x -> set dist-aux dist-aux + 1 ]
  report dist-aux
end

to-report secure-route? [#route]
  let sum-aux 0
  foreach #route [ x -> if ([habitable] of one-of nodes with [id = x]) < 1 [ set sum-aux sum-aux + 1] ] ;; este = 0
  report sum-aux
end

to-report my-secure-routes
  report filter [ x -> secure-route? x = 0] exits_routes
end

to-report my-least-bad-route
  report first ( sort-by [ [route1 route2 ] -> secure-route? route1 < secure-route? route2 ] exits_routes )
end

to-report all-my-signals
  report fire? + fire-sound? + attacker? + attacker-sound? + bomb? + bomb-sound? + corpses? + scream? + running-people?
end


; BREADTH FIRST SEARCH: It returns the shortest path (list of "who" property) between two nodes.
; The graph satisfies the triangular property, so the shortest list is the shortest path

; queue      = A list of unexplored nodes. A list with all nodes (except current node) in the call to the function.
; next-nodes = A list with the secuence of nodes to be explored. A list with only origin node in the call to the function;
; res        = A list of lists with the diferent routes. An empty list in the call to the function
; origin     = The start point
; target     = The node we want to reach

to-report bfs [#origin #target]
  ; We need a queue list, an ordered list with the nodes to explore (next-nodes) and a list of results (res)
  let current    #origin
  let queue      remove current (n-values (count nodes) [x -> x])
  let next-nodes (list #origin)
  let res        []      ; A list to modify values
  let rc         res     ; A copy to iterate over it

  ; The list of neighbours of the current node, only those that have not been explored yet.
  let neighs ( filter [x -> not member? x next-nodes] [[who] of reacheables] of node current )

  ; In the first iteration we have an empty list (res), so we have to populate it with the origin node neighbours'
  ; If any of this neighbours is the destiny, we are going to return the result
  foreach neighs [
    x ->
    if member? x queue [ set next-nodes (lput x next-nodes) ]
    ifelse x = #target [report (list current x)][set res lput (list current x) res]
  ]

  ; Iterator. Go to the next node and explore its neighbours until we reach the target
  while [not empty? queue]
  [
    set current first next-nodes
    set next-nodes bf next-nodes
    set queue (remove current queue)
    set rc res

    ; The list of neighbours of the current node, only those that have not been explored yet.
    set neighs ( filter [x -> not member? x next-nodes] [[who] of reacheables] of node current )
    foreach neighs [ x -> if member? x queue [ set next-nodes (lput x next-nodes) ] ]

    foreach rc [
      x ->
      if last x = current [
        foreach neighs [
          n ->
          ifelse n = #target [
            report (lput n x)
          ][
            if member? n queue [
              set aux (lput n x)
              set res (lput aux res)
            ]
          ]
        ]
        set res (remove x res)
      ]
    ]
  ]
  report [] ; If this report is reached, probably we set a target node that does not exists in the graph
end
@#$#@#$#@
GRAPHICS-WINDOW
374
8
1011
399
-1
-1
12.33333333333334
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
50
0
30
0
0
1
ticks
30.0

BUTTON
374
406
429
441
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

SLIDER
20
64
160
97
num-peacefuls
num-peacefuls
1
1000
404.0
1
1
NIL
HORIZONTAL

SLIDER
20
98
160
131
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
433
406
490
441
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

MONITOR
1029
162
1127
207
not-app: Red
not-app-rescued
17
1
11

MONITOR
1030
303
1127
348
NIL
not-app-killed
17
1
11

SLIDER
18
385
162
418
leaders-percentage
leaders-percentage
0.0
1.0
0.2
0.05
1
NIL
HORIZONTAL

MONITOR
1029
117
1127
162
app: Blue
app-rescued
17
1
11

MONITOR
1030
258
1127
303
NIL
app-killed
17
1
11

SLIDER
195
65
339
98
attackers-efectivity
attackers-efectivity
0
1
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
20
31
160
64
max-iter
max-iter
0
1000
495.0
5
1
NIL
HORIZONTAL

SWITCH
195
32
339
65
shooting?
shooting?
0
1
-1000

SWITCH
21
173
159
206
app-info?
app-info?
0
1
-1000

BUTTON
374
445
429
480
once
go
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
1

SLIDER
21
207
159
240
app-percentage
app-percentage
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
1029
206
1127
251
total-rescued
app-rescued + not-app-rescued
17
1
11

MONITOR
1030
348
1127
393
total-killed
app-killed + not-app-killed
17
1
11

SLIDER
18
452
161
485
mean-speed
mean-speed
1
2
1.1
0.01
1
NIL
HORIZONTAL

PLOT
816
406
1011
541
not alerted people
tick
people
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"not-alerted-app" 1.0 0 -13345367 true "" "if not-alerted-not-app > 0 or not-alerted-app > 0 [plot not-alerted-app]\n\n"
"not-alerted-not-app" 1.0 0 -2674135 true "" "if not-alerted-not-app > 0 or not-alerted-app > 0 [plot not-alerted-not-app]\n"

PLOT
1128
117
1323
252
rescued
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot not-app-rescued"
"pen-1" 1.0 0 -13345367 true "" "plot app-rescued"

PLOT
1128
258
1323
393
killed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot app-killed"
"pen-1" 1.0 0 -2674135 true "" "plot not-app-killed"

SLIDER
19
486
162
519
max-speed-deviation
max-speed-deviation
0
0.5
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
41
10
167
39
WORLD PARAMS
12
0.0
1

TEXTBOX
29
364
172
383
PEACEFULS PARAMS
12
0.0
1

TEXTBOX
207
10
352
39
VIOLENTS PARAMS
12
0.0
1

SLIDER
195
99
339
132
attackers-speed
attackers-speed
0.1
2
0.8
0.1
1
NIL
HORIZONTAL

INPUTBOX
267
157
339
218
target-agent
-1.0
1
0
Number

INPUTBOX
195
157
267
218
target-node
-1.0
1
0
Number

TEXTBOX
48
153
181
172
APP PARAMS
12
0.0
1

TEXTBOX
198
139
351
168
-1 to deactivate targets
12
0.0
1

MONITOR
1027
9
1124
54
violents-killed
violents-killed
0
1
11

SLIDER
18
418
161
451
not-alerted-speed
not-alerted-speed
0
1
0.5
0.05
1
NIL
HORIZONTAL

PLOT
1127
405
1324
540
accidents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot not-app-accident"
"pen-1" 1.0 0 -13345367 true "" "plot app-accident"

MONITOR
1030
405
1127
450
app: Blue
app-accident
0
1
11

MONITOR
1030
451
1127
496
not-app: Red
not-app-accident
17
1
11

MONITOR
1030
496
1127
541
accidents
app-accident + not-app-accident
0
1
11

SWITCH
23
264
160
297
first-blood
first-blood
1
1
-1000

TEXTBOX
65
246
153
264
Triggers
12
0.0
1

SWITCH
23
298
160
331
crowd-running
crowd-running
0
1
-1000

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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-rescued</metric>
    <metric>not-app-rescued</metric>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>not-alerted</metric>
    <enumeratedValueSet variable="num-violents">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="150"/>
    </enumeratedValueSet>
    <steppedValueSet variable="app-percentage" first="0" step="10" last="100"/>
    <steppedValueSet variable="leaders-percentage" first="0" step="0.1" last="1"/>
  </experiment>
</experiments>
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
