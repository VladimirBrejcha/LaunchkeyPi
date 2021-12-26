## State

module Color
  DISABLED = 0
  BLUE = 40
  VIOLET = 49
  PINK = 53
  YELLOW = 13
  GREEN = 21
  RED = 5
end

module PadState
  DISABLED = Color::DISABLED
  ENABLED = Color::PINK
  ENABLED_2 = Color::BLUE
  ENABLED_3 = Color::GREEN
end

configured = get[:configured]

pads = (96..103).to_a + (112..119).to_a

## Events

live_loop :inControl_events do
  note, velocity = sync "/midi:launchkey_mini_mk3_daw_port:16/note_on"
  if note == 12 and velocity == 127
    print "entered daw mode"
  elsif note == 12 and velocity == 0
    print "entered basic mode"
  else
    print "received param"
    print note
    print "with value"
    print velocity
  end
end

live_loop :pad_events do
  use_real_time
  note, velocity = sync "/midi:launchkey_mini_mk3_daw_port:1/note_on"
  if velocity != 0 && pads.include?(note)
    switch_pad_light note
  end
end

## Actions

# Switches between daw and basic mode
define :daw_mode do |enter|
  if enter
    midi_raw 159, 12, 127
  else
    midi_raw 159, 12, 0
  end
end

# Changes color of a pad
define :light_pad do |pad, color|
  midi_raw 144, pad, color
  state = get[:pads_state].to_h
  state[pad] = color
  set :pads_state, state
end

define :switch_pad_light do |pad|
  s = get[:pads_state][pad]
  if s == PadState::DISABLED
    light_pad pad, PadState::ENABLED
  elsif s == PadState::ENABLED
    light_pad pad, PadState::ENABLED_2
  elsif s == PadState::ENABLED_2
    light_pad pad, PadState::ENABLED_3
  else
    light_pad pad, PadState::DISABLED
  end
end

define :update_all_lights do
  for (key, value) in get[:pads_state]
    light_pad key, value
  end
end

## ============= ##

## Init

if not configured
  print "configuring"
  
  set :configured, true
  
  state = pads.reduce({}) do |hash, value|
    hash[value] = PadState::DISABLED
    hash
  end
  set :pads_state, state
  
  daw_mode true
  update_all_lights
end
