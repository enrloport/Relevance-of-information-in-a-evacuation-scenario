extensions [fuzzy nw csv]

globals [
  exit-nodes
  secure-rooms
  leaders
  peacefuls
  violents
  violents-killed
  flag

  app-not-alerted
  app-accident
  app-killed
  app-rescued
  app-in-secure-room
  not-app-not-alerted
  not-app-accident
  not-app-killed
  not-app-rescued
  not-app-in-secure-room
  total-with-app
  total-without-app
  total-killed
  total-rescued

  low-risk
  high-risk
  close-to-me
  far-from-me
  not-in-danger
  in-danger
  fear-level
  sensibility-level
  panic-level
  density-level
  speed-level
  accident-prob-set

  degree-of-consistency-R1
  degree-of-consistency-R2
  degree-of-consistency-R3
  degree-of-consistency-R4
  reshaped-consequent-R1
  reshaped-consequent-R2
  reshaped-consequent-R3
  reshaped-consequent-R4

  t-agent
  transitable-edges
  num-nodes
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
  scream?
  running-people?
  corpses?          ; If an agent dies in the node, the corpse will lay in the floor for the rest of the simulation as a sign of danger
  lock?
  leaders?
  police?
  id
  info
  capacity
  density
  hidden-places
  hidden-people
  residents
  reacheables       ; Reacheable neighbors
  visibles          ; Visible neighbors
  nearest-danger    ; Distance to closest danger
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
  fear
  sensibility
  in-panic
  hidden
  leadership
  last-locations
  location
  base-speed
  speed
  max-speed
  next-location
  p-type
  route
  state
  p-timer
  bad-area
  efectivity
  detected
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;*****************************************  TO SETUP  ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  clear-all
  create-fuzzy-sets

  set app-killed           0
  set app-rescued          0
  set app-accident         0
  set not-app-killed       0
  set not-app-rescued      0
  set not-app-accident     0
  set violents-killed      0
  set flag                 0

  let max-x                0
  let max-y                0
  let file                 (csv:from-file nodes-file ",")
  let cabecera             first file
  set file                 bf file

  foreach file [
    row ->
      if (item 1 row) > max-x [set max-x (item 1 row)]
      if (item 2 row) > max-y [set max-y (item 2 row)]
  ]

  resize-world 0 (max-x + 1) 0 (max-y + 1)

  ;; CREATE NODES
  foreach file [
    row ->
    create-nodes 1 [
      (foreach cabecera row [
        [c r] ->
        run (word "set " c " " r)
      ])
      set shape         "circle"
      set color         blue
      set residents     0
      set density       0
      set hidden-people 0
    ]
  ]


  ;; CREATE EDGES
  set file (csv:from-file edges-file ",")
  set cabecera first file
  set file bf file
  foreach file [
    row ->
    ask one-of nodes with [id = item 0 row] [
      create-link-with one-of nodes with [id = (item 1 row)] [
        set node1       (item 0 row)
        set node2       (item 1 row)
        set dist        (item 2 row)
        set visibility  (item 3 row) * visibility-mod
        set sound       (item 4 row) * sound-mod
        set transitable (item 5 row)
        set lockable?   (item 6 row)
        set flow        (item 7 row)
        if transitable = 0 [ set hidden? true ]
      ]
    ]
  ]
  set transitable-edges (link-set links with [transitable > 0] )
  set num-nodes count nodes
  ask nodes [
    set reacheables turtle-set ( [other-end] of my-links with [transitable > 0] )
    set visibles    turtle-set ( [other-end] of my-links with [visibility  > 0] )

  ]

  nw:set-context nodes (links with [transitable > 0])


  ;; CREATE PECEFULS
  create-people num-peacefuls [
    set shape             "person"
    set p-type            "peaceful"
    set state             "not-alerted"
    set hidden            false
    set attacker-sighted  0
    set attacker-heard    0
    set fire-sighted      0
    set fire-heard        0
    set bomb-sighted      0
    set bomb-heard        0
    set fear              0
    set percived-risk     0
    set in-panic          0
    set p-timer           0
    set base-speed        not-alerted-speed
    set speed             base-speed
    set bad-area          nobody
    set leader-sighted    nobody
    set route             []
    set location          one-of nodes with [residents < capacity]
    set last-locations    (list location)
    set next-location     location
    set sensibility       floor( ( random-normal 0.5 0.2 ) * 100 )
    if sensibility > 100 [set sensibility 100]

    ifelse random 100 < app-percentage [ set app true ][ set app false ]

    ifelse random-float 1 < leaders-percentage[
      set leadership     (random-float 1) + 0.1
      set route path_to  (min-one-of nodes with [id - floor id < 0.099] [distance myself] )
      set color          yellow
    ][
      set leadership     0
      set color          white
    ]

    ask location [set residents residents + 1 ]
    move-to location
  ]
  if target-agent >= num-nodes [
    set t-agent target-agent ; The agent 0 will be created with who = (0 + number of nodes), so we need to adjust this number
    ask person t-agent [set size 2]
  ]

  let positions []
  if initial-positions != "" [
    set positions (read-from-string initial-positions)
  ]

  ;; CREATE VIOLENTS
  create-people num-violents [
    set shape             "person"
    set p-type            "violent"
    set speed             attackers-speed
    set detected          0
    set color             17
    set size              1.5
    set route             []
    set last-locations    []
    set efectivity        attackers-efectivity
    set location          min-one-of nodes with [member? who positions][attacker?]
    if location = nobody  [set location one-of nodes]
    set next-location     location
    move-to location
    ask location          [set attacker? 1]
  ]

  ;; CREATE TURTLE SETS
  set exit-nodes          turtle-set (nodes  with [id - floor id < 0.099])
  set secure-rooms        turtle-set (nodes  with [lock? > 0])
  set violents            turtle-set (people with [p-type = "violent"] )
  set peacefuls           turtle-set (people with [p-type = "peaceful"])
  set leaders             turtle-set (people with [leadership > 0])

  set total-with-app      count peacefuls with [app]
  set total-without-app   count peacefuls with [not app]

  set app-not-alerted     total-with-app
  set not-app-not-alerted total-without-app

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;****************************************    TO GO    ****************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  set app-not-alerted         count people with [state = "not-alerted" and app]
  set app-in-secure-room      count people with [state = "at-save" and app]
  set not-app-not-alerted     count people with [state = "not-alerted" and not app]
  set not-app-in-secure-room  count people with [state = "at-save" and not app]

  let saved (not-app-in-secure-room + app-in-secure-room)

  ;; STOP conditions
  if (count peacefuls - saved = 0) or (max-iter > 0 and ticks = max-iter) [stop]

  update-world

  ; A label "T" for the target node. The target agent will be greater than other agents
  if target-node  > -1 [ ask node target-node [set label who] ]
  if target-agent >= num-nodes [
    set t-agent target-agent
    ifelse person t-agent != nobody [ ask person t-agent [set size 2] ][ set target-agent -1 ]
  ]
  ask violents [
    violents-belive
    violents-desire
    violents-intention
  ]
  ask peacefuls [
    exit-reached?
    if not in-secure-room? [casualty?]

    peaceful-believe
    peaceful-desire
    peaceful-intention

    if fear > 0 [set fear fear - 1]
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
    any-target?        [set state "finding-target"]
    true               [set state "aggressive-behaviour"]
  )
end

to violents-intention
  (ifelse
    state = "finding-target"       [find-target]
    state = "aggressive-behaviour" [be-aggressive]
  )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;   STATES FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to avoid-police
  ;set label "ap"
  ; TO DO
end


to be-aggressive
  ;set label "ba"
  let loc location
  if random-float 1 < attack-prob [
    ifelse shooting?[
      let loc-aux location
      let visib-aux current-visibles
      (ifelse
        any? peacefuls with [visible-target? and location = loc-aux] [shoot-target (one-of peacefuls with [visible-target? and location = loc-aux])]
        any? peacefuls with [ visible-target? and member? location visib-aux ] [
          ifelse random-float 1 < 0.5 [
            shoot visib-aux
          ][
            if location = next-location [attacker-next-location]
            violent-advance
          ]
        ][
          if location = next-location [attacker-next-location]
          violent-advance
      ])
    ][
      ifelse any? peacefuls with [location = loc and not hidden][
        attack
      ][
        if location = next-location [attacker-next-location]
        violent-advance
      ]
    ]
  ]
end

to find-target
  set label "ft"
  let loc-aux location
  ifelse target-agent > -1 and person t-agent != nobody [  ; The attacker will search for the target agent first
    let target-location ([location] of person t-agent)
    ifelse loc-aux = target-location [
      ifelse shooting? [shoot-target person t-agent][attack-target person t-agent]
      set route []
    ][
      if empty? route or last route != target-location [ set route (path_to target-location) ]
      follow-route
    ]
  ][
    if target-node >= 0[
      ifelse [who] of location = target-node [
        ifelse shooting? [shoot [visibles] of location][attack]
        set target-node -1
        ask location [set label ""]
      ][
        if empty? route [ set route ( path_to node target-node ) ]
        follow-route
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TODO contar los ticks para las gráficas


to violent-advance
;  show "walking"
  carefully[
    ask (link ([who] of location) ([who] of next-location) ) [
      ifelse locked? > 0 [
        ask myself [
          set next-location location
          face next-location
          walk
        ]
      ][
        if flow-counter > 0 and locked? = 0[
          ask myself [
            if [capacity > residents] of next-location [
              face next-location
              walk
            ]
          ]
          set flow-counter flow-counter - 1
        ]
      ]

    ]
  ][]

end


to attacker-next-location
  let destinations current-reacheables
  let ll last-locations
  (ifelse
    any? destinations with [residents - hidden-places > 0][
      set next-location one-of destinations with [residents - hidden-places > 0]
    ]
    any? destinations with [not (member? self ll)] [
      set next-location one-of destinations with [not (member? self ll)]
    ]
    true [
      foreach last-locations [
        x ->
        ask x [
          if member? x destinations [
            ask myself [ set next-location x ]
            stop
          ]
        ]
      ]
    ]
  )
end

to walk
  let dist-aux distance next-location
  ifelse speed > dist-aux [fd dist-aux][fd speed]

  if distance next-location < distance location [ ; The agent has reached next-location
    let l-aux ([who] of location)
    let nl-aux ([who] of next-location)
    if detected > 0 [
      ask location [set attacker? (attackers-efectivity * ([visibility] of link l-aux nl-aux ) ) ]
      ask next-location [set attacker? 1]
    ]

    set location next-location

    ;    ask location [set residents residents + 1]
    ifelse not member? location last-locations [ ; Last visited node will be put in the last position
      set last-locations (lput location last-locations)
    ][
      set last-locations (lput location (remove location last-locations))
    ]
  ]
end

to attack-target [#target]
  if detected = 0 [
    set detected 1
    set color red
  ]
  let l location
  if random-float 1 < efectivity [
    ask #target [ died-agent "attack" ]
  ]
end

to attack
  if detected = 0 [
    set detected 1
    set color red
  ]
  let l location
  if random-float 1 < efectivity [
    let peaceful-aux one-of peacefuls with [location = l and not hidden]
    if peaceful-aux != nobody [ ask peaceful-aux [ died-agent "attack" ] ]
  ]
end

to shoot-target [#target]
  if detected = 0 [
    set detected 1
    set color red
  ]
  update-noise
  if random-float 1 < efectivity [
    ask #target [ died-agent "shoot" ]
  ]
end


to shoot [#visibles]
  if any? peacefuls with [visible-target? and member? location current-visibles][
    if detected = 0 [
      set detected 1
      set color red
    ]
    update-noise
    if random-float 1 < efectivity [
      ask one-of peacefuls with [member? location #visibles][ died-agent "shoot" ]
    ]
  ]
end


to update-noise
  ask location [
    set attacker-sound? attacker-sound? + shoot-noise
    ask my-links with [sound > 0] [
      let s-aux sound
      ask other-end [set attacker-sound? attacker-sound? + shoot-noise * s-aux]
    ]
  ]
end

to-report current-reacheables
  let linked-aux (turtle-set ([[other-end] of my-links with [transitable > 0 and (lockable? = 0 or locked? = 0) ]] of location ))
  report linked-aux
end

to-report current-visibles
  let linked-aux (turtle-set ([[other-end] of my-links with [visibility > 0 ]] of location ))
  report linked-aux
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
  (ifelse
    any-leader? [
      leader-influence
    ]
    true [

      let percived-signals 0
      ifelse app-info? and app and app-trigger [
        set percived-signals 1
      ][
        update-signals
        set percived-signals (attacker-sighted + fire-sighted + bomb-sighted + attacker-heard
          + fire-heard + bomb-heard + scream-heard + corpse-sighted + running-people)
        if percived-signals > 1 [set percived-signals 1]
      ]

      if percived-signals > 0 [
        set fear min (list (fear + 1 + number-of-signals) 100 )

        compute-panic fear sensibility
        set in-panic degree-of-consistency-R3

        let dis-aux 15

        if any? ([visibles] of location) with [all-my-signals > 0] [
          let near-signal max-one-of ([visibles] of location) [all-my-signals]
          set dis-aux ( [dist] of ( link ([who] of location) ([who] of near-signal) ) )
        ]

        compute-danger (dis-aux) (percived-signals * 100)
        if degree-of-consistency-R2 > degree-of-consistency-R1 and degree-of-consistency-R2 > percived-risk[
          set percived-risk degree-of-consistency-R2
          if speed = not-alerted-speed [
            set base-speed ( precision ((random-normal mean-speed max-speed-deviation) / 2) 2 )
            set speed base-speed
          ]
        ]
      ]
    ]
  )

end

to peaceful-desire
  ifelse percived-risk > 0[
    (ifelse
      secure-exit?               [set state "reaching-exit"]
      in-secure-room?            [set state "at-save"]
      in-panic > 0.5             [set state "in-panic"]
      p-timer > 0                [set state "waiting"]
      any-violent?               [set state "avoiding-violent"]
      congested-path?            [set state "avoiding-crowd"]
      secure-route? route        [set state "following-route"]
      app-pack?                  [set state "asking-app"]
      true                       [set state "running-away" ] )
  ][
    keep-working
  ]
end


to peaceful-intention
  set speed base-speed

  (ifelse
    state = "at-save"         [set color gray       to-stay]
    state = "asking-app"      [set color white      ask-app]
    state = "avoiding-violent"[set color brown      avoid-violent]
    state = "avoiding-crowd"  [set color sky        avoid-crowd]
    state = "following-route" [set color green      follow-route]
    state = "in-panic"        [set color 13         irrational-behaviour]
    state = "reaching-exit"   [set color green      go-to-exit]
    state = "running-away"    [set color orange     run-away]
    state = "waiting"         [set color 58         to-wait]
    state = "with-leader"     [set color 48         follow-leader])

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;   STATES FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to avoid-crowd
  stop-hidden
  set route []
  set next-location min-one-of ([reacheables] of location) [residents / capacity]
  face next-location
  advance
end

to go-to-exit
  stop-hidden
  if route = [] or [ id - floor id ] of last route > 0.099  [
    set route (path_to one-of ([visibles] of location) with [id - floor id < 0.099])
    face (item 1 route)
  ]
  follow-route
end

to to-wait
  let loc-aux location
  (ifelse
    in-secure-room? [
      if [residents / capacity] of location > 0.75 [
        to-stay
      ]
    ]
    visible-target? and any? violents with [ location = loc-aux ] [
      stop-hidden
      set p-timer 0
      avoid-violent
    ]
    lockable-room? location [
      to-lock
    ]
    bad-area != nobody and better-location? [
      let n-aux bad-area
      let nl-aux max-one-of ([reacheables] of location) [distance n-aux]
      ifelse nl-aux != nobody [
        set next-location nl-aux
        face next-location
        advance
      ][
        show "beter-location = nobody"
      ]
      set p-timer p-timer - 1
    ]
    true [
      set p-timer p-timer - 1
    ]
  )
end

to to-stay
  stop-hidden
  let loc-aux location
  (ifelse
    ([attacker?] of location) = 1 [ ; TODO: si no hay atacante en mi area/sala

;    any? reachea [ ; TODO: si no hay atacante en mi area/sala
      set state "avoiding-violent"
    ]
    any? current-reacheables with [attacker? = 1][
      to-lock
    ]
    location != next-location [
      advance
    ]
    distance location > 0.3 [
      face location
      fd 0.4
    ]
    [residents / capacity] of location > 0.5 [
      set loc-aux [floor id] of location
      let node-aux one-of ([reacheables] of location) with [floor id = (loc-aux) and residents / capacity < 0.75]
      if node-aux != nobody [
        set next-location node-aux
        face next-location
        advance
      ]
    ]
  )
end


to-report better-location?
  let dist-aux distance bad-area
  let n-aux bad-area
  let bet-loc one-of ([reacheables] of location) with [distance n-aux > dist-aux]
  if bet-loc != nobody [report true]
  report false
end

to avoid-violent
  stop-hidden
  carefully [

    set speed ( base-speed + ( fuzzy:evaluation-of close-to-me (distance bad-area) ) )

    (ifelse
      must-I-hide?                                      [ hide ]
      must-I-lock?                                      [ to-lock ]
      must-I-fight? and random-float 1 < defense-prob   [ fight ]

      [attacker?] of location = 1 [
        if route = [] [set route path_to one-of exit-nodes]
        follow-route
      ]

      [attacker?] of next-location = 1 [
        set next-location location
        face next-location
        advance
      ]

      member? bad-area [visibles] of location [
        if not secure-route? route [
          set route path_to one-of (turtle-set location (best-visibles bad-area))
        ]
        follow-route
      ]

      true [set bad-area nobody]
    )
  ][ show "All violents are dead" show bad-area]
end

to-report in-the-same-area? [#loc #bad]
  let area   [floor id] of #loc
  let area-v [floor id] of #bad
  let module 0
  ifelse area > area-v [ set module area mod area-v ][ set module area-v mod area ]
  report module = 0
end

to-report best-visibles [#bad-node]
  let area   [floor id] of location
  let area-v [floor id] of #bad-node
  let module 0
  ifelse area > area-v [ set module area mod area-v ][ set module area-v mod area ]

  ifelse module != 0 [
    let dest ( ([visibles] of location) with [ (max (list (floor id) area)) mod (min (list (floor id) area)) = 0 ]  )
    ;let dest (max-one-of ([visibles] of location) with [ floor id = area ] [distance #bad-node] )
    ifelse dest != nobody [ report dest ][ report (list location) ]
  ][
    let visib-aux (([visibles] of location) with [capacity - residents > 1])
    let res visib-aux with [ not in-the-way? ([location] of myself) (node who) #bad-node ]
    report res
  ]
end

to-report best-visible [#bad-node]
  let area   [floor id] of location
  let area-v [floor id] of #bad-node
  let module 0
  ifelse area > area-v [ set module area mod area-v ][ set module area-v mod area ]

  ifelse module != 0 [
    let dest (max-one-of ([visibles] of location) with [floor id = area] [distance #bad-node] )
    ifelse dest != nobody [ report dest ][ report location ]
  ][
    let visib-aux reverse ( sort-on [distance #bad-node] (([visibles] of location) with [capacity - residents > 1]) )
    foreach visib-aux [ n ->
      if not in-the-way? location n #bad-node [ report n]
    ]
    report location
  ]
end

to follow-leader
  stop-hidden
  ifelse leader-sighted != nobody [
    if route != ([route] of leader-sighted)[ set route ([route] of leader-sighted) ] ; The leader is going to share the route with other agents
    follow-route
  ][
    ifelse route != [] [ ; Maybe the leader is dead, but if he has shared the route, follow the route
      follow-route
    ][
      set state "running-away"
      run-away
    ]
  ]
end

to run-away
  stop-hidden
  ifelse leadership > 0 [
    if route = [] [set route path_to (min-one-of nodes with [member? (node who) exit-nodes] [distance myself] )]
    follow-route
  ][
    if location = next-location [search-intuitive-node]
    advance
  ]
end

to hide
  if leadership = 0 [set color grey]
  if hidden = false[
    set hidden true
    ask location [set hidden-people hidden-people + 1]
    set p-timer (random-normal 5 1)
  ]
end

to to-lock
  stop-hidden
  if bad-area != location[
    ask location [
      set color 103
      ask my-links with [lockable? > 0] [
        if locked? = 0 [
          set transitable 0
          set visibility 0
          set locked? 1
        ]
      ]
    ]
  ]

end

to fight
  stop-hidden
  if leadership = 0 [set color black]
  if random-float 1 < 0.1 [
    let loc-aux location
    carefully [
      ask one-of violents with [location = loc-aux] [
        set violents-killed violents-killed + 1
        die
        ask location [set attacker? 0]
      ]
    ][ show "No violent"]
  ]
end

to keep-working
  if random-float 1 < 0.007 or distance location >= speed[
    if location = next-location [
      let nl-aux (one-of ([reacheables] of location) with [capacity - residents > 1] )
      if nl-aux != nobody [
        set next-location nl-aux
        face next-location
      ]
    ]
    advance
  ]
end

to stop-hidden
  if hidden [
    set hidden false
    ask location [set hidden-people hidden-people - 1]
  ]
end

to to-unlock
  show location
  ask location [
    ask my-links with [lockable? > 0] [
      if locked? = 1 [
        set transitable 1
        set visibility 1
        set locked? 0
      ]
    ]
  ]
end

to irrational-behaviour
  stop-hidden
  (ifelse
    route != [] [
      follow-route
    ]
    any? ([visibles] of location) with[member? (node who) exit-nodes] [ ; The agent has sighted an exit
      set route (path_to one-of ([visibles] of location) with[member? (node who) exit-nodes])
      follow-route
    ]
    any? violents with [next-location = [location] of myself][
      let nl-aux (min-one-of ([reacheables] of location) with [capacity - residents > 1] [attacker?]  )
      if nl-aux != nobody [
        set next-location nl-aux
        face next-location
        advance
      ]
    ]
    any? (peacefuls with [location = [location] of myself and state != "in-panic"]) [
      let nl-aux ( [next-location] of one-of (peacefuls with [location = [location] of myself and state != "in-panic"]) )
      if nl-aux != nobody [
        set next-location nl-aux
        face next-location
        advance
      ]
    ]
    location = next-location [
      let nl-aux (one-of ([reacheables] of location) with [capacity - residents > 1] )
      ifelse nl-aux != nobody [
        set next-location nl-aux
        face next-location
      ][
        set next-location location
        face next-location
      ]
        advance
    ]
    true [advance])

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   CHECK FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report in-the-way? [#p1 #p2 #bad-node]
  let x1 [xcor] of #p1
  let y1 [ycor] of #p1
  let x2 [xcor] of #p2
  let y2 [ycor] of #p2
  let x  [xcor] of #bad-node
  let y  [ycor] of #bad-node
  report ( (x - x1)*(y2 - y1) ) = ( (x2 - x1)*(y - y1) )
end

to-report visible-target?
  report not hidden and not in-secure-room?
end

to-report lockable-room? [#l]
  report [lock?] of #l > 0
end

to-report any-target?
  report target-node > 0 or (target-agent >= num-nodes and (person t-agent) != nobody)
end

to-report any-leader?
  report leadership = 0 and any? leaders with [ location = ([location] of myself) and not member? state ["not-alerted" "in-panic"] ]
end

to exit-reached?
  if member? location exit-nodes and state != "not-alerted"[
    ifelse app [set app-rescued app-rescued + 1][set not-app-rescued not-app-rescued + 1]
    ask location [set residents residents - 1]
    die
  ]
end

to-report app-pack?
  report app-info? and app and app-trigger and route = []
end

to-report must-I-hide?
  ifelse ([hidden-places - hidden-people] of location)  > 0 [report true][report false]
end


to-report must-I-lock?
  let floor-aux ([floor id] of location)
  report (not in-the-same-area? location bad-area) and lockable-room? location
end

to-report must-I-fight?
  let loc-aux location
  report ([attacker?] of location = 1) and enough-people? loc-aux
end

to-report congested-path?
  report [residents * 1.1] of next-location > [capacity] of next-location
end

to-report any-violent?
  if secure-route? route [report false]
  let bad-node min-one-of (turtle-set location ([visibles] of location)) with [attacker? = 1][distance myself]
  if bad-node != nobody[
    set bad-area bad-node
    report true
  ]
  report false
end

to-report in-secure-room?
  report [lock?] of location > 0 and (any? ([links] of location) with [lockable? + locked? = 2] )
end

to-report number-of-signals
  let res 0
  let signs (list attacker-sighted fire-sighted bomb-sighted attacker-heard fire-heard bomb-heard scream-heard corpse-sighted running-people )
  foreach signs [ x -> if x > 0 [set res res + 1] ]
  report res
end

to-report enough-people? [#loc]
  report ( ([residents] of location) > ( 11 * count (violents with [#loc = location]) ) )
end


to casualty?
  compute-accident-prob ([density] of location ) (floor (speed * 100))
  let acc-prob degree-of-consistency-R4 * ([capacity] of location) * 0.001 ; Mortal accident
  if random-float 1 < acc-prob [died-agent "casualty"]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   ACTION FUNCTIONS  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to update-signals
  set attacker-sighted  attacker-sighted + [attacker?]       of location
  set fire-sighted      fire-sighted     + [fire?]           of location
  set bomb-sighted      bomb-sighted     + [bomb?]           of location
  set attacker-heard    attacker-heard   + [attacker-sound?] of location
  set fire-heard        fire-heard       + [fire-sound?]     of location
  set bomb-heard        bomb-heard       + [bomb-sound?]     of location
  set scream-heard      scream-heard     + [scream?]         of location
  set corpse-sighted    corpse-sighted   + [corpses?]        of location
  set running-people    running-people   + [running-people?] of location
end

to-report path_to [#dest]
  let r []
  ask location [set r (nw:turtles-on-weighted-path-to #dest dist)]
  report r
end

to update-location
  ask location [set residents residents - 1]
  ask next-location [set residents residents + 1]
  set location next-location
  ifelse member? location last-locations [
    set last-locations ( lput location (remove location last-locations) )
  ][
    set last-locations (lput location last-locations)
  ]
end

to advance ; Go to next-node
  carefully [
    ifelse distance next-location < distance location [ ; The agent has reached next-location
      update-location
    ][
      if location != next-location [
        update-running-people
        update-flow
      ]
    ]
  ][
    show "next-location = nobody"
  ]
end

to follow-route
  ifelse location = next-location [
    (ifelse
      (not member? location route or not member? next-location route) [
        let nl-aux min-one-of ([visibles] of location) with [member? (node who) ([route] of myself)] [distance myself]
        ifelse nl-aux != nobody[
          let route-aux (path_to nl-aux)
          set route (sentence route-aux (sublist route ((position nl-aux route) + 1) (length route) ) )
        ][
          set route []
          set next-location location
        ]
      ]
      location = last route [
        set p-timer (floor random-normal 5 1)
        set route []
      ]
      true [
        let loc-aux location
        let pos-aux (position loc-aux route)
        set next-location ( item (pos-aux + 1) route)
        face next-location
    ])
  ][
    ifelse p-type = "violent" [violent-advance][advance]
  ]
end

to update-running-people
  if percived-risk > 0 [
    ask next-location [ set running-people? running-people? + 0.02]
    ask location[
      set running-people? running-people? + 0.02
      ask my-links with [visibility > 0 ][
        let visib-aux visibility
        ask other-end [set running-people? (running-people? + 0.01) * visib-aux ]
      ]
    ]
  ]
end

to update-flow
  let link-aux (link ([who] of location) ([who] of next-location) )

  ask link-aux [
    if flow-counter >= 1 [
      ask myself [
        if [capacity > residents] of next-location [
          face next-location
          let dist-aux distance next-location
          ifelse speed > dist-aux [fd dist-aux][fd speed]
          if distance next-location < distance location [update-location]
        ]
      ]
      set flow-counter flow-counter - 1
    ]
  ]

end

to search-intuitive-node
  carefully [
    let destinations ([reacheables] of location)
    let secure-destinations (destinations with [attacker? < 1])
    if any? secure-destinations [set destinations secure-destinations]

    let ll last-locations
    let not-visited one-of destinations with[ not (member? self ll) and capacity - residents > 1 ]

    ifelse not-visited != nobody [
      set next-location not-visited
    ][
      foreach last-locations [
        x ->
        ask x [
          if member? x destinations [
            ask myself [ set next-location x ]
            stop
          ]
        ]
      ]
    ]
    face next-location
  ][show "there is no good node"]
end

to leader-influence
  if speed = not-alerted-speed [
    set base-speed ( precision ((random-normal mean-speed max-speed-deviation) / 2)  2 )
    set speed base-speed
  ]
  set leader-sighted ( max-one-of leaders with [location = ([location] of myself) and not member? state ["not-alerted" "in-panic"] ] [leadership] )
  set percived-risk [percived-risk] of leader-sighted
  (ifelse
    any-violent?     [set state "avoiding-violent"]
    congested-path?  [set state "avoiding-crowd"]
    true             [set state "with-leader"])
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
      ask location [ ask my-links with [sound > 0] [ask other-end [set scream? 0.3 * ([sound] of myself )]] ]
      die
    ]
    #cause = "shoot"    [
      ifelse app [set app-killed app-killed + 1] [set not-app-killed not-app-killed + 1]
      die
    ])
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

; It changes the attacker? atribute in nodes depending on danger location, also updates the counter-flow in edges
to update-world
  ask nodes [
    set fire?           0
    set attacker?       0
    set bomb?           0
    set attacker-sound? 0
    set fire-sound?     0
    set bomb-sound?     0
    set scream?         0
    set running-people? 0
    set density         floor (100 * residents / capacity)
    if  density > 100 [set density 100]
    if id - floor id < 0.099 and any? violents [ set nearest-danger ( distance (min-one-of violents [distance myself]) ) ]
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
        set attacker? 1
        ask my-links [
          let visib-aux visibility
          let sound-aux sound
          let dist-aux dist
          if visibility > 0 [
            ask other-end [
              set attacker? (attacker? + (visib-aux * efct-aux) )
              if attacker? > 0.99 [
                ifelse any? violents with[location = myself] [
                  set attacker? 1
                ][

                  set attacker? 0.99
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;    APP FUNCTIONS    ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to ask-app
  (ifelse
    app-mode = 0 [ ; The app gives to the agent a path to evacuate
      set route exit-path
      set state "following-route"
    ]
    app-mode = 1 [ ; The app gives to the agent a path to a secure-room
      if not in-secure-room?[
        let path-aux secure-room-path
        if path-aux != nobody [
          set route path-aux
          set state "following-route"
        ]
      ]
    ]
    app-mode = 2 [ ; The app gives to the agent the closest option (secure room or exit)
      let dests reverse (sort-on [distance myself] (turtle-set exit-nodes secure-rooms) )
      set route []
      foreach dests [ n ->
        let route-aux (path_to n)
        if secure-route? route-aux [
          set route route-aux
          stop
        ]
      ]
  ])
end

to-report app-trigger
  if first-blood and app-killed + not-app-killed > 0 [report true]
  if crowd-running and (count peacefuls with [speed > not-alerted-speed]) >= what-is-a-crowd? [report true]
  report false
end

to-report secure-room-path
  let rooms-aux reverse ( sort-on [distance myself] (nodes with [lock? > 0 and (count my-links with[lockable? > 0 and locked? = 0]) > 0 ]) )
  foreach rooms-aux [ n ->
    let route-aux (path_to n)
    if secure-route? route-aux [ report route-aux]
  ]
  report nobody
end

to-report exit-path
  report path_to ( min-one-of (nodes with [id - floor id < 0.099]) [distance myself] )
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;   FUZZY FUNCTIONS   ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to create-fuzzy-sets
  set low-risk              fuzzy:gaussian-set [0   20 [0 100]]
  set high-risk             fuzzy:gaussian-set [100 10 [0 100]]

  set close-to-me           fuzzy:gaussian-set [0   10 [0 100]]
  set far-from-me           fuzzy:gaussian-set [100 10 [0 100]]

  set not-in-danger         fuzzy:gaussian-set [10 2 [0 10]]
  set in-danger             fuzzy:gaussian-set [0  2 [0 10]]

  set fear-level            fuzzy:gaussian-set [100 30 [0 100]]
  set sensibility-level     fuzzy:gaussian-set [100 30 [0 100]]

  set panic-level           fuzzy:gaussian-set [100 30 [0 100]]

  set density-level         fuzzy:gaussian-set [100 12 [0 100]]
  set speed-level           fuzzy:gaussian-set [200 35 [0 200]]

  set accident-prob-set     fuzzy:gaussian-set [100 20 [0 100]]
end


to compute-accident-prob [#density #speed]
  ;; Rule 4: IF density AND speed THEN accident
  let degree-of-consistency-R4a fuzzy:evaluation-of density-level #density
  let degree-of-consistency-R4b fuzzy:evaluation-of speed-level #speed
  set degree-of-consistency-R4 (runresult (word "min" " list degree-of-consistency-R4a degree-of-consistency-R4b"))

end

to compute-panic [#fear #sensibility]

  ;; Rule 3: IF fear AND sensibility THEN panic-level
  let degree-of-consistency-R3a fuzzy:evaluation-of fear-level #fear
  let degree-of-consistency-R3b fuzzy:evaluation-of sensibility-level #sensibility
  set degree-of-consistency-R3 (runresult (word "min" " list degree-of-consistency-R3a degree-of-consistency-R3b"))

end

to compute-danger [#dist #risk-level]

  ;; COMPUTATION OF DEGREES OF CONSISTENCY BETWEEN FACTS (INPUTS) AND ANTECEDENTS FOR EACH RULE
  ;; Rule 1: IF low risk OR far from me THEN not in danger
  let degree-of-consistency-R1a fuzzy:evaluation-of low-risk #risk-level
  let degree-of-consistency-R1b fuzzy:evaluation-of far-from-me #dist
  set degree-of-consistency-R1 (runresult (word "max" " list degree-of-consistency-R1a degree-of-consistency-R1b"))

  ;; Rule 2: IF High Risk OR Close to me THEN in danger
  let degree-of-consistency-R2a fuzzy:evaluation-of high-risk #risk-level
  let degree-of-consistency-R2b fuzzy:evaluation-of close-to-me #dist
  set degree-of-consistency-R2 (runresult (word "max" " list degree-of-consistency-R2a degree-of-consistency-R2b"))

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                             ;;
;;******************************************  NODES  ******************************************;;
;;                                                                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report secure-exit?
  let exit-aux one-of ( ([visibles] of location) with [member? (node who) exit-nodes] )
  if exit-aux != nobody [
    report secure-route? (path_to exit-aux)
  ]
  report false
end

to-report secure-route? [#route]
  if empty? #route [report false]
  foreach #route [
    x ->
    if [attacker?] of x = 1 [report false]
  ]
  report true
end


to-report my-least-bad-route [#routes]
  ; TODO
end

to-report all-my-signals
  report fire? + fire-sound? + attacker? + attacker-sound? + bomb? + bomb-sound? + corpses? + scream? + running-people?
end


















@#$#@#$#@
GRAPHICS-WINDOW
370
207
1290
527
-1
-1
20.73333333333334
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
43
0
14
0
0
1
ticks
30.0

BUTTON
186
440
241
475
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
197
154
342
187
num-peacefuls
num-peacefuls
1
1000
350.0
1
1
NIL
HORIZONTAL

SLIDER
19
155
163
188
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
296
440
353
475
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
673
145
737
190
not-app
not-app-rescued
17
1
11

MONITOR
881
145
946
190
not-app
not-app-killed
17
1
11

SLIDER
197
187
342
220
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
609
145
674
190
app
app-rescued
17
1
11

MONITOR
815
145
881
190
app
app-killed
17
1
11

SLIDER
20
288
164
321
attackers-efectivity
attackers-efectivity
0
0.95
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
186
405
355
438
max-iter
max-iter
0
1000
0.0
5
1
NIL
HORIZONTAL

SWITCH
20
189
165
222
shooting?
shooting?
0
1
-1000

SWITCH
21
638
160
671
app-info?
app-info?
0
1
-1000

BUTTON
241
440
296
475
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
197
220
342
253
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
738
145
803
190
total-rescued
app-rescued + not-app-rescued
17
1
11

MONITOR
945
145
1011
190
total-killed
app-killed + not-app-killed
17
1
11

SLIDER
197
319
342
352
mean-speed
mean-speed
1
2
2.0
0.01
1
NIL
HORIZONTAL

PLOT
373
10
603
147
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
"not-alerted-app" 1.0 0 -13345367 true "" "ifelse not-app-not-alerted > 0 or app-not-alerted > 0 [\n  plot app-not-alerted\n  ][if flag = 0 [plot app-not-alerted set flag 1] ]\n\n"
"not-alerted-not-app" 1.0 0 -2674135 true "" "if not-app-not-alerted > 0 or app-not-alerted > 0 [plot not-app-not-alerted]\n"

PLOT
608
10
803
145
rescued
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot 100 * not-app-rescued / total-without-app"
"pen-1" 1.0 0 -13345367 true "" "plot 100 * app-rescued / total-with-app"

PLOT
815
10
1010
145
killed
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot 100 * app-killed / total-with-app"
"pen-1" 1.0 0 -2674135 true "" "plot 100 * not-app-killed / total-without-app"

SLIDER
197
352
342
385
max-speed-deviation
max-speed-deviation
0
0.5
0.15
0.01
1
NIL
HORIZONTAL

TEXTBOX
207
137
350
156
PEACEFULS PARAMS
12
0.0
1

TEXTBOX
36
135
182
154
VIOLENTS PARAMS
12
0.0
1

SLIDER
20
323
164
356
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
92
415
164
476
target-agent
-1.0
1
0
Number

INPUTBOX
20
415
92
476
target-node
-1.0
1
0
Number

TEXTBOX
121
540
254
559
APP PARAMS
12
0.0
1

MONITOR
20
477
164
522
violents-killed
violents-killed
0
1
11

SLIDER
197
286
342
319
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
1021
10
1218
145
accidents
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot 100 * not-app-accident / total-without-app"
"pen-1" 1.0 0 -13345367 true "" "plot 100 * app-accident / total-with-app"

MONITOR
1021
145
1089
190
app
app-accident
0
1
11

MONITOR
1090
145
1155
190
not-app
not-app-accident
17
1
11

MONITOR
1154
145
1220
190
total
app-accident + not-app-accident
0
1
11

SWITCH
21
560
159
593
first-blood
first-blood
0
1
-1000

TEXTBOX
169
566
234
586
Triggers
12
0.0
1

SWITCH
21
594
159
627
crowd-running
crowd-running
0
1
-1000

SLIDER
160
594
299
627
what-is-a-crowd?
what-is-a-crowd?
1
20
20.0
1
1
NIL
HORIZONTAL

INPUTBOX
16
8
186
68
nodes-file
nodesP.csv
1
0
String

INPUTBOX
186
8
356
68
edges-file
edgesP.csv
1
0
String

SLIDER
20
256
164
289
attack-prob
attack-prob
0
1
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
161
638
299
671
app-mode
app-mode
0
2
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
23
680
318
740
0 = The app will recomend nearest exit\n1 = The app will recomend a secure-room\n2 = The app will recomend the closest option\n                                   (secure-room or exit)
12
0.0
1

TEXTBOX
418
160
534
190
    App   =  Blue\nNot-app =  Red
12
0.0
1

MONITOR
1228
147
1292
192
app
app-in-secure-room
17
1
11

MONITOR
1292
147
1358
192
not-app
not-app-in-secure-room
17
1
11

MONITOR
1359
147
1425
192
total
not-app-in-secure-room + app-in-secure-room
17
1
11

PLOT
1228
10
1423
147
secure room
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
"default" 1.0 0 -13345367 true "" "plot 100 * app-in-secure-room / total-with-app"
"pen-1" 1.0 0 -2674135 true "" "plot 100 * not-app-in-secure-room / total-without-app"

SLIDER
197
253
342
286
defense-prob
defense-prob
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
16
77
186
110
visibility-mod
visibility-mod
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
190
77
358
110
sound-mod
sound-mod
0
1
1.0
0.01
1
NIL
HORIZONTAL

INPUTBOX
20
356
164
416
initial-positions
[0 73]
1
0
String

SLIDER
20
223
165
256
shoot-noise
shoot-noise
0
1
0.5
0.01
1
NIL
HORIZONTAL

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="peace-250-500" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="peace500-vi1-app" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident + not-app-accident</metric>
  </experiment>
  <experiment name="peace500-v1-not-app" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident + not-app-accident</metric>
  </experiment>
  <experiment name="peace200-v1-not-app" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident + not-app-accident</metric>
  </experiment>
  <experiment name="peace600-v1-app" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident + not-app-accident</metric>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="peace600-v1-not-app" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident + not-app-accident</metric>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-info?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="peace500-v2-app2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>app-accident + not-app-accident</metric>
    <metric>app-in-secure-room + app-in-secure-room</metric>
    <metric>app-rescued + not-app-rescued</metric>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="peace500-v2-not-app" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>app-killed</metric>
    <metric>not-app-killed</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>app-accident + not-app-accident</metric>
    <metric>app-in-secure-room + app-in-secure-room</metric>
    <metric>app-rescued + not-app-rescued</metric>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-info?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="p-150-600-v-2-app-on" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-peacefuls" first="150" step="50" last="600"/>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="p-150-600-v-2-app-off" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-peacefuls" first="150" step="50" last="600"/>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="prueba" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-peacefuls" first="150" step="50" last="250"/>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="app-T-F-shooting-T-F-peace-150-600-visib-1-sound-1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-peacefuls" first="150" step="50" last="600"/>
    <enumeratedValueSet variable="visibility-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sound-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-positions">
      <value value="&quot;[0 73]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="app-T-F-shooting-T-F-peace-150-600-visib-0-sound-0" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-peacefuls" first="150" step="50" last="600"/>
    <enumeratedValueSet variable="visibility-mod">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sound-mod">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-positions">
      <value value="&quot;[0 73]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="app-T-F,attacker-speed-0.6-1.5,shooting-T,peace-350,mods-1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sound-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="attackers-speed" first="0.6" step="0.1" last="1.5"/>
    <enumeratedValueSet variable="initial-positions">
      <value value="&quot;[0 73]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leaders-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="app-T-F,leaders-percent-0-1,shooting-T,peace-350,mods-1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>not-app-killed</metric>
    <metric>app-killed</metric>
    <metric>app-killed + not-app-killed</metric>
    <metric>not-app-accident</metric>
    <metric>app-accident</metric>
    <metric>not-app-accident + app-accident</metric>
    <metric>not-app-in-secure-room</metric>
    <metric>app-in-secure-room</metric>
    <metric>not-app-in-secure-room + not-app-in-secure-room</metric>
    <metric>not-app-rescued</metric>
    <metric>app-rescued</metric>
    <metric>not-app-rescued + app-rescued</metric>
    <enumeratedValueSet variable="app-info?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-peacefuls">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sound-mod">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-violents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shoot-noise">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attack-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-efectivity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackers-speed">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-positions">
      <value value="&quot;[0 73]&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="leaders-percentage" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="app-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defense-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="not-alerted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-deviation">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-iter">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="app-mode">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-blood">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crowd-running">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="what-is-a-crowd?">
      <value value="20"/>
    </enumeratedValueSet>
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
