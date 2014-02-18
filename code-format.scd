Synth names are strings "someSynth"
Arguments between pipes character and with default values |freq=600|
variables are declared after arguments with a statement for each variable:
 var env ...; // the envelope
 var sig ...; //your uGens

use message style s.sendMsg(\...) and call the arguments of a synth as symbols \freq

Always use a semi-colon on that last line, unless it's being closed by a {} on the same line
A space should follow ever comma
Spaces should surround all mathematical operators
Use Class() instead of Class.new()Short variable names when possible, clear variable names when not -- if abbreviation is needed, try and think carefully about who else might read your code
