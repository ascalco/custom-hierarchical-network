;; The present file must be included included in NetLogo models to recreate an organizational design (or, hierarchical structure).
;; The integration to other models can be performed by means of the primitive "__includes" (e.g. "__includes ["file-name.nls"]", see Dictionary for more details).
;; The present code constitutes the original version (v.1.00) and it has been developed with/for Netlogo 5.2 (2015) (Y. Wilensky, 1999).
;; Sourcecode by Andrea Scalco (2015), University of Verona, Dept. of Philosophy, Education and Psychology. eMail at: andrea.scalco@univr.it.
;; The hereby program is licensed under 'Creative Commons (cc by-nc-sa)'. Briefly, you are free to work/share/apapt it for non-commercial purpose.
;; The only requirement is to give appropriate credit to the original version and indicate if changes were made.
;; Please, read the attached document to find more information about the program.

undirected-link-breed [vrtLinks vrtLink]      ;; Vertical hierarchy has uni-directional links
undirected-link-breed [hrzLinks hrzLink]    ;; Links among peers of the same layer are bi-directional

globals [
  source       ; it is used to store the source of the link in "fromAgent" chose by the user through the mouse input
  destiny      ; similarly to "source", it is stored to memorize the end of the link in "toAgent"
  ]

turtles-own [
  hier-position  ;; it defines the hierarchical position of the agent inside the organization
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SETUP PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Clean the virtual world from everything, reset the points clicked with the mouse by the user and setup the agents' variable
to setup
  clear-output
  set source -1     ;; set source and destiny to -1, as turtles' ID starts from 0
  set destiny -1
  clear-all
  ask patches [set pcolor 2]
  crt #employees
  [ set-employees ]
  reset-ticks 
  output-print ("Setup complete: simulation's ready")
end

to set-employees
  setxy random-xcor random-ycor
  set color green
  set hier-position 0
  set shape "person business"
  set size 1.5
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; CREATE COSTUM CONNECTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Assign the origin of the link to the turtles that has been pointed by the mouse
to fromAgent
  if (mouse-down? = true)
  [ set source who? ] ;; "Who?" is a reporter that is used to identify the ID of the turtle that has been chosen with the mouse
end

;; Assign the destiny of the link to the turtles that has been pointed by the mouse
to toAgent  
  if (source != -1)
  [
    set destiny -1
    if (mouse-down? = true)
    [ set destiny who? ]   ;; "Who?" is a reporter that is used to identify the ID of the turtle that has been chosen with the mouse
    if ((source != -1) and (destiny != -1) and (source != destiny)) 
    [ 
      ;; If there is a positive difference between the hier. position of the turtles chosen, the program create a vertical link
      if ([hier-position] of turtle source = [hier-position] of turtle destiny)
      [
        ask turtle source [create-hrzLink-with turtle destiny]
      ]
      ;; If the turtles chosen share the same hier. position, the program create an horizional (dual direction) link
      if ([hier-position] of turtle source < [hier-position] of turtle destiny)
      [
        ask turtle source [create-vrtLink-with turtle destiny ask vrtLinks [set thickness 0.2]]
      ]
    ]
  ]
  if (destiny != -1)
  [ wait 0.2 output-show (word "Agent n. " source " and agent n. " destiny " have been connected") ]
  reset-perspective
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; USER (MOUSE) INTERACTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Report the pointed agent by the (left) click of the mouse
;; It is used by several procedures.

to-report who?
  let pointedAgent nobody
  set pointedAgent min-one-of turtles [distancexy mouse-xcor mouse-ycor]
  ifelse [distancexy mouse-xcor mouse-ycor] of pointedAgent < 1
  [ watch pointedAgent
    ; ask pointedAgent [set size 3 wait 0.3 set size 1]
    report [who] of pointedAgent]
  [ report who? ]
end

to delete-agent
  if (mouse-down? = true)
  [ output-show (word "Agent n. "  who? " has been deleted")
    ask turtle who? [ wait 0.2 die ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ASSIGN LAYERS PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This procedure assign a layer to a specific turtle specified by the user thanks to the slider "#Layer"
to assign-layers
  let pointed-agent nobody
  let requested-layer #layer
  if (mouse-down? = true)
  [ set pointed-agent turtle who?
    assign-them! (pointed-agent) (requested-layer) ]
  update-n-display-layers
  reset-perspective
end

;; Assign to the agents a layer.
;; The layer can be requested by the user (trhough "assign-layers" procedure) or automatically randomly generated (through "assign-random-layers").
to assign-them! [pointed-agent requested-layer]
        watch pointed-agent
        ask pointed-agent
        [ set hier-position requested-layer ]
        wait 0.2
        output-show (word "Virtual employee n. " [who] of pointed-agent " has been assigned to layer " [hier-position] of pointed-agent)  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RANDOMIZE LAYERS AND CONNECTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
;; Assign to each agent a random layer (the maximum number of layers is fixed by the user throug "max-layer" slider command)
to assign-random-layers
  clear-all-links
  ask turtles [set hier-position 0]
  let iter 0
  while [any? turtles with [hier-position = 0] ]
  [ let pointed-agent turtle iter
    assign-them! (pointed-agent) (1 + random max-layer) 
    set iter iter + 1 ]
  update-n-display-layers
  sort-employees-by-layers
  reset-perspective
end

to create-random-vrtLinks
  if all? turtles [hier-position = 0] [warning-message-1]
  clear-vrtLinks
  let mx max [hier-position] of turtles  
  let hp 1
  let sup-layer nobody ;; "peers" is used to store the agentset of the agents that share the same hier-position (except the asking turtle itself)
  while [hp != (mx)]
  [
    ask turtles with [hier-position = hp]
    [
      set sup-layer turtles with [hier-position = ([hier-position] of myself + 1) ]
      if (count sup-layer = 0) [ warning-message-2 (hp + 1)]
      create-vrtLink-with one-of sup-layer    ;; Vertical links are directional (bottom-up)
    ]
    set hp hp + 1
  ]
  ask vrtLinks [set thickness 0.2 set color white]
end

to create-random-hrzLinks
  if all? turtles [hier-position = 0] [warning-message-1]
  clear-hrzLinks
  let mx max [hier-position] of turtles  
  let hp 1
  let peers nobody ;; "peers" is used to store the agentset of the agents that share the same hier-position (except the asking turtle itself)
  while [hp != (mx + 1)]
  [
    ask turtles with [hier-position = hp]
    [
      set peers turtles with [(hier-position = hp) and (who != [who] of myself)] 
      create-hrzLinks-with n-of (random (count peers)) peers       ;;; Horizontal links among peers are random and have dual directions
    ]
    set hp hp + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; WARNING MESSAGES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to warning-message-1
  output-show  "WARNING: To create an organizational structure employees must be assigned each one to a specific layer:"
  output-show "please, use 'Randomize layer' or assign them manually through 'Assign layers'."
  user-message "WARNING: To create an organizational structure employees must be assigned each one to a specific layer. Press 'Halt' to return to the simulation."
  stop
end

to warning-message-2 [missing-layer] 
  output-show "WARNING: At least one layer is missing within the organizational structure:"
  output-show (word "please, use 'Assign layers' to assign at least one employee to layer " missing-layer)
  user-message "WARNING: A layer is missing. Check the output for more details. Press 'Halt' to return to the simulation"
  stop
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; CLEAR & REVERSE LINKS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to clear-vrtLinks
  ask vrtLinks [die]
end

to clear-hrzLinks
  ask hrzLinks [die]
end

to clear-all-Links
  ask links [die]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; VISUALIZATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Display the layer of each agent as a label.
to update-n-display-layers
  ask turtles [ set label hier-position ]
end

;; Create and visualize a sort of structure to facilitate the comprhension fo the desired design.
;; Very useful to perceive the gaps among layers.
to sort-employees-by-layers
  let mx max [hier-position] of turtles
  let hp 1
  let ypos (mx * -2) 
  while [hp != (mx + 1 ) ]
  [
    ask turtles with [hier-position = hp]
    [
      setxy random-xcor ypos
      set color scale-color green hp (hp - 1) (hp * 1.5)
    ]
    set hp hp + 1
    set ypos ypos + 5
  ]
 repeat 25 [ layout-spring turtles links 0.1 5 2]
 output-show "Organizational structure has been sketched"
end
@#$#@#$#@
GRAPHICS-WINDOW
363
14
802
474
16
16
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
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
123
18
187
51
Setup
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

BUTTON
21
257
88
304
from...
fromAgent
T
1
T
OBSERVER
NIL
F
NIL
NIL
1

BUTTON
95
258
169
304
...to
toAgent
T
1
T
OBSERVER
NIL
T
NIL
NIL
1

TEXTBOX
24
207
250
259
Custom organizational design\nPress \"From..\" to fix the origin of the link\nPress \"To..\" to point the end of the link
11
0.0
1

MONITOR
182
259
233
304
Links
count links
17
1
11

OUTPUT
808
14
1323
145
12

MONITOR
179
105
237
150
#Layer-1
count turtles with [hier-position = 1]
17
1
11

MONITOR
179
155
236
200
#Layer-2
count turtles with [hier-position = 2]
17
1
11

MONITOR
241
105
296
150
#Layer-3
count turtles with [hier-position = 3]
17
1
11

SLIDER
24
105
57
197
#Layer
#Layer
1
6
1
1
1
NIL
VERTICAL

BUTTON
68
105
167
161
Assign layers
Assign-layers
T
1
T
OBSERVER
NIL
L
NIL
NIL
1

TEXTBOX
25
68
296
100
Press \"Assign layers\" to activate the assignation of the layear to each employees (from 1 to 5).
11
0.0
1

MONITOR
241
155
297
200
#Layer-4
count turtles with [hier-position = 4]
17
1
11

BUTTON
119
348
220
381
Randomize layers
assign-random-layers 
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
21
348
113
381
max-layer
max-layer
1
6
6
1
1
NIL
HORIZONTAL

TEXTBOX
22
315
315
346
Press to randomize the assignation of layers (please, use the slider to specify the maximum number of desired layers).
11
0.0
1

BUTTON
68
165
167
198
Update structure
sort-employees-by-layers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
120
413
242
446
Random vrt links
create-random-vrtLinks
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
244
258
341
304
Delete agent
Delete-agent
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
247
413
338
482
Remove all links
clear-all-links
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
120
449
242
482
Random hrz links
create-random-hrzLinks
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
413
114
447
Remove vrt links
clear-vrtLinks
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
449
114
482
Remove hrz links
clear-hrzLinks
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
21
392
345
410
Press to create random links among the agents (or to clear them).
11
0.0
1

MONITOR
300
105
354
150
#Layer-5
count turtles with [hier-position = 5]
17
1
11

MONITOR
301
155
355
200
#Layer-6
count turtles with [hier-position = 6]
17
1
11

SLIDER
23
17
115
50
#employees
#employees
3
25
25
1
1
Employees
HORIZONTAL

TEXTBOX
823
361
1285
459
Things that should be improved: \n- Highest layer is not connected if there is more than one agents\n- Avoid to use global variables for user interaction (from.. ...to)
13
4.0
1

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

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
NetLogo 5.2.0
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
