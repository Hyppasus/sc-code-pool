Synth names strings "someSynth"
Arguments between pipes and with default values |freq=600|
variables are declared after arguments with a statement for each variable:
 var env ...;// the envelope
 var sig ...;//your uGens

use message style s.sendMsg(\...) and call the arguments of a synth as symbols \freq
