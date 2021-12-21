# CSCI 5611: Final Project

## Group

* Alexandra Hanson (hans7203)
* Nathan Ringo ()

## Simulation: A particle-ulary good campfire

<video controls width="100%"><source src="https://cdn.remexre.xyz/files/a926fd22ba1da695671c6aa42e2838812736c9d6.mp4" type="video/mp4"></video>

## TO DO:

The report should:
* Discuss the key algorithms and approaches you used. What were the computational bottlenecks
to your approach? What would be the limiting factor to scaling up 10x or 100x bigger than what
you turned in?
* Address any of the specific questions outlined above for the project you choose
* Suggest some directions the project could be extended in the future. What are the limitations of
your current versions and how might you get pass them if given more time?

This report or webpage should be written in complete sentences (e.g., no bullet points).
Additionally, the report should be well structured (e.g., section headers), and should make use of
figures, images, and videos to help convey the key ideas.

Since we chose to do option 4 (i.e. implementing an animation technique we didn't)
implement in class, we also need to:

* Explicitly discuss the connection between your topic and topics from the course

## Feedback from our peers

At the time we shared our work with our peers during the progress report, we did
not yet have a working renderer so there was nothing visual to show off. Most 
feedback included something to the effect of "Get something on the screen!",
albeit put more kindly. We are happy to report we have succeed in addressing 
this feedback by debugging our renderer and creating our campfire scene.

A suggestion made by one of our peers was to try to make the campfire look as
realistic as possible. Although we wanted to keep the scene cute and fun, we 
attempted to add elements of realism through semi-accurate lighting, as well as
fine-tuning our particle parameters and rendering different transparency levels,
colors, and sizes for a given particle depending on its age.  

## Our work and the state of the art

A common state-of-the-art approach for animating fire and/or smoke appears to 
be the use of fluid dynamics (i.e., the Navier-Stokes Equations) for simulating 
flow. In contrast, we chose to use a particle system, in part because it seemed much 
simpler to implement and did not require us to have such a firm grasp of fluid
dynamics. Additionally, we thought it might be interesting to see how convincing
we could make our particle system when compared with more realistic simulations
using Navier-Stokes.

In practice, it seems that particle systems are a little more common for 
simulating fire and smoke. However, it is also common for existing libraries
for game development to use billboarding techniques to avoid the cost of
rendering 3D simulations. This is true of approaches that use a particle system
and of approaches that use fluid dynamics for simulating fire and smoke. In this
sense, we differ from both state-of-the-art and practical implementations: we
do not use billboarding techniques as is often done in practice, and we also 
chose to use a particle system unlike the state-of-the-art techniques that use
fluid dynamics.

### TO DO:

* discuss what the related state-of-the-art techniques are
and discuss how the methods used by your code or tools related to the state-of-the-art.

## Code

TO DO: Share code repo w/ Prof. Guy & Dan

## Credit

### Objects:

* Conifer macedonian pine
  * https://www.cgtrader.com/free-3d-models/plant/conifer/conifer-macedonian-pine
* mushrooms.obj / mushrooms.mtl
  * https://www.cgtrader.com/free-3d-models/plant/other/low-poly-small-mushrooms-set
* campfire
  * https://www.cgtrader.com/free-3d-models/exterior/landscape/campfire-03629b01-7d0f-45fc-8466-ff748e13732e

Code?