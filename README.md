# JoyOverlay
A widget for a highly-configurable joystick monitoring overylay, intended for livestreaming purposes.

# Configuration
The name of the config file will follow the name of the executable, and if no match is found, a new ini file will be spawned with a set of defaults


## Overall Configuration
```ini
[configaxes]
	; Search phrase, uses lazy matching 
	search=
	; in case of multiple device results such as multi vjoy (not yet implemented)
	next = 0
	windowWidth = 200
	windowHeight = 200
	axisweight=2
	pipweight=3
	backgroundcolor= 0x003300
	axiscolor= 0xFFFFFF
	pipcolor= 0xFFFFFF
```
`search` uses AHK's built-in `InStr()` lazy-match function, and if left blank, will match on the first available DirectInput Joystick Device

(to-do: handle multiple match with the `next` parameter)

`windowWidth` and `windowHeight` are given in pixel size (to-do: handle non-100% DPI scaling)

`axisweight` and `pipweight` are given in pixel size 

colors are given in 6-character Hex code, with `0x` prefix

## Pip Configuration

The number of active pips is unconstrained. All ini sections after the first (`[configaxes]`) will be read as pip definitions.
Use `enable` to turn on/off pip sections without needing to delete.
Due to trig problems (to-do: get better at that) the palette of Radial pips is limited to a subset of the Cartesian pips

```ini
	; Add sections for more Pips as desired, follow existing structure for Cartesian (standard) and Radial Pips
	; (config input validation not yet implemented)
	
	; Available Styles of Pip (cursor)
	; radial only supports ones marked in (r)
	; + (r)
	; x (r)
	; T
	; A (r)
	; V (r)
	; |
	; -
	; [] 
	; <> (r)
	; [o] (corners and dot in center)
	
	; Axis uses: X Y Z Rx Ry Rz S0 S1
	; Axis specials, use Min, Mid, or Max to lock pip to edge/center
```

### Cartesian (Linear) Pip 
```ini
[crosspip]
	enable = 1
	axishoriz= X
	axisvert= Y
	inverthoriz=0
	invertvert= 0
	size = 20
	style = +
```
### Radial (Rotary) Pip
```ini
[radialpip]
	enable = 0
	radial = 1
	axis = Z
	style = V
	size = 20
	invert =0
	maxangle = 45
	radius = 50
```
