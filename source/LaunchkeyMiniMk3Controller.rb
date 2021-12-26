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
  if velocity != 0
    switch_pad_light note
  end
end

## State

pads = (96..103).to_a + (112..119).to_a

state = pads.reduce({}) do |hash, value|
  hash[value] = Color::DISABLED
  hash
end

module Color
  DISABLED = 0
  BLUE = 40
  VIOLET = 49
  PINK = 53
  YELLOW = 13
  GREEN = 21
  RED = 5
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
  state[pad] = color
end

# Switch enabled/disabled
define :switch_pad_light do |pad|
  if state[pad] == Color::DISABLED
    light_pad pad, Color::PINK
  else
    light_pad pad, Color::DISABLED
  end
end

## ============= ##

##| daw_mode true
