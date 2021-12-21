# CSCI 5611: Final Project

## Group

* Alexandra Hanson (hans7203)
* Nathan Ringo (ringo025)

## Simulation: A particle-ulary good campfire

<video controls width="100%"><source src="https://cdn.remexre.xyz/files/a926fd22ba1da695671c6aa42e2838812736c9d6.mp4" type="video/mp4"></video>

## Key Algorithms

Our fire simulation was created using a particle system, the physics for which
was implemented more or less the standard way we covered in class. For the
simulation, we keep track of a particle's position and velocity and use a 
vector for acceleration that remains constant over time (this acts like a 
constant "wind" on the smoke, blowing it upwards toward the sky). The fine-tuning
of our parameters was crucial to this project, and the combination of mathematical 
intuition, physics, and recognition of aesthetic serendipities necessary to do so
was honed by the 5611 coursework and greatly influenced by the material covered in
this class.

The rendering of the fire and smoke used a bunch of instanced spheres, with handtuned functions controlling the size and color of the particle. This size is computed by `min(sqrt(age * 0.08), age)`.
This results in a particle that grows at a fixed rate until `t=0.08`, at which point it rapidly grows, slowing its growth over time as it "disperses".
This effect is strengthened by a fade-out, where the opacity simply linearly decreases, becoming fully transparent at `t=4`.
After that time, the particle is destroyed.

Though this is relatively simple, it produces quite good effects, since the smoke is dense enough that smoke spheres are able to occlude fire spheres (despite depth-sorting), producing fairly organic fire shapes.

Adjacent to the material covered in this course, it is of note that because we
implemented this simulation from scratch in `OCaml`, we also implemented a great
deal of the library code we used (i.e. all of the code from source in `/lib`,
all the way from the asset and object file handling to the camera and mat4). 
This of course was based on existing open-source libraries in other languages, 
but porting these computations over to `OCaml` presented an additional fun 
challenge.

### Computational bottlenecks

The main computation bottleneck was honestly OCaml; until OCaml gets multicore support ("coming soon" in 2014, "coming soon" in 2021), there's a hard upper limit on the number of particle updates that can be done.
However, looking at the generated assembly for the core loop of the physics calculation, we'd significantly benefit from better floating-point code generation in general.
Currently, a line like:

```ocaml
p.pos <- (px +. (vnx *. dt), py +. (vny *. dt), pz +. (vnz *. dt));
```

Compiles to code like:

```assembly
// Allocate the tuple; on amd64 OCaml uses r15 as a "bump pointer"
sub    $0x50,%r15
cmp    0x8(%r14),%r15
jb     4848c1 <camlDune__exe__Particle__update_129+0x1a1> // calls the GC and retries
lea    0x8(%r15),%rax

// pz +. (vnz *. dt)
add    $0x40,%rax
movq   $0x4fd,-0x8(%rax)
mov    0x10(%r13),%rdi
mov    0x10(%rsi),%rdx
movsd  (%rdx),%xmm0
mulsd  (%rbx),%xmm0
addsd  (%rdi),%xmm0
movsd  %xmm0,(%rax)

// py +. (vny *. dt)
lea    -0x10(%rax),%rdi
movq   $0x4fd,-0x8(%rdi)
mov    0x8(%r13),%rdx
mov    0x8(%rsi),%rcx
movsd  (%rcx),%xmm0
mulsd  (%rbx),%xmm0
addsd  (%rdx),%xmm0
movsd  %xmm0,(%rdi)

// px +. (vnx *. dt)
lea    -0x10(%rdi),%rdx
movq   $0x4fd,-0x8(%rdx)
mov    0x0(%r13),%rcx
mov    (%rsi),%rsi
movsd  (%rsi),%xmm0
mulsd  (%rbx),%xmm0
addsd  (%rcx),%xmm0
movsd  %xmm0,(%rdx)

// Write the header into the tuple's allocation
lea    -0x20(%rdx),%rsi
movq   $0xc00,-0x8(%rsi)

// Write the tuple to the mutable field, checking for a write barrier
mov    %rdx,(%rsi)
mov    %rdi,0x8(%rsi)
mov    %rax,0x10(%rsi)
mov    %r12,%rdi
callq  578700 <caml_modify>
```

As opposed to more optimal code, like:

```assembly
// Perform all the additions and multiplications in parallel
vfmadd132ss %xmm4, %xmm1, %xmm3
vfmadd132ps %xmm2, %xmm5, %xmm0

// Write them back
vmovss      %xmm3, 8(%rdi)
vmovlps     %xmm0, (%rdi)
```

I suspect the missing ingredients are:

- Better escape analysis, to know that pointer-comparison isn't used on the tuple at any point.
  (This would probably require link-time optimization, but that's fine.)
- Tuple unboxing.
  This would let us represent the tuple as three separate fields, as long as we know pointer-comparison isn't used on the tuple (see above).
- Write barrier elision for value types.
  For non-multicore OCaml, the runtime doesn't need to be involved with writes of types that don't contain pointers (e.g floats).
  I believe this optimization is already present for float arrays, but from generated assembly (not pictured), it appears this is not done when writing to mutable record fields.
  (This optimization holds for parallel programs running on amd64 machines as well.)
- A peephole optimization to hoist the computation above the stores.
- A peephole optimization to combine the mul instructions with each other, and add instructions with each other (i.e. vectorization via peephole).
  This could also take the form of a typical vectorization pass, but that's unnecessary in this case.
- A peephole optimization to widen (i.e. vectorize) the stores.
- A peephole optimization to fuse the mul and add instructions to an FMA instruction.

Once the code's been optimized as above, there would also be essentially no pressure on the scalar registers, so the actual update loop could itself then be vectorized to be four-wide.

`llvm-mca` (now "linked to but not explicitly recommended see legal statements A through K" by Intel) estimates the SIMD'd-but-not-loop-vectorized implementation to take about 60% fewer cycles.
The array map operation ought to fit in the uOp cache alongside the update function regardless of vectorization, so the primary benefit of the loop vectorization is to improve memory access times.
With a prefetch (which may need to be programmer-inserted if experience with C and Rust serves, though "teaching the compiler about `Array.iter`" might allow it to be compiler-inserted), each iteration of the vectorized loop (which handles 4 particles) ought to have roughly four cycles of latency to load the particle data.
If instead the computation were to be vectorized to be two-wide, the fetch could happen during the previous iteration's computation.
Roughly estimating (since we didn't go through the trouble of modifying the OCaml compiler to test this!), a 4x speedup per core ought to be possible with all the above.

### However

As it turns out, our simulation was originally keeping particles alive until `t=500`; after lowering this to `t=4`, we're easily able to increase the rate of particle generation by a factor of 25-50 before dropping below the "console gaming is just as good as PC" line (30fps).
At that point, however, the bottleneck appears to still be the CPU (tested on an Intel i7-6700K and a NVIDIA GeForce RTX 3080 Ti).
Since the CPU is 8-thread and the problem is embarassingly parallel, a roughly 16-32x increase in the number of particles ought to be possible.

## Future work

There are several things we would like to do to extend this work. This includes:

* Enhancing the scene by making the ground less flat and more "ground-like", 
adding some kind of skybox, texturing the trees, etc.
* Adding shadows from the smoke and other objects in the scene
* Perhaps using a heat map to change the color and/or transparency of our
particles rather than just using their age
* Allowing the fire to expand or die out over time

We would also consider re-implementing this scene using fluid dynamics rather
than a particle system. It might be interesting to compare the computational
overhead of these two methods and see which performs better.

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

### Methods used by our code and its relation to SOTA

Our transparency also used non-SOTA techniques, but this lead to an overall better artistic effect.
Rather than using depth peeling or a more modern technique for implementing order-independent transparency, we simply sort particles by depth.
As mentioned above, this results in the fire shapes being more organic, since they're often partially occuluded by smoke particles, so it was a net win for the artistic and aesthetic appeal of the project.

## Code

Our code is publicly accessible at the following link: [https://github.com/remexre/particleulary-good-campfire](https://github.com/remexre/particleulary-good-campfire)

## Credit

### Objects:

* Conifer macedonian pine
  * https://www.cgtrader.com/free-3d-models/plant/conifer/conifer-macedonian-pine
* mushrooms.obj / mushrooms.mtl
  * https://www.cgtrader.com/free-3d-models/plant/other/low-poly-small-mushrooms-set
* campfire
  * https://www.cgtrader.com/free-3d-models/exterior/landscape/campfire-03629b01-7d0f-45fc-8466-ff748e13732e

### Code:

* 2D Simplex Noise
  * Used in making the ground appear somewhat less shiny
  * https://thebookofshaders.com/edit.php#11/2d-snoise-clear.frag
* Camera
  * Used as an inital attempt at a camera (this has changed greatly)
  * https://learnopengl.com/Getting-started/Camera
* [TGLS](https://erratique.ch/software/tgls)
  * OpenGL bindings for OCaml
* [glfw-ocaml](https://github.com/SylvainBoilard/GLFW-OCaml)
  * GLFW bindings for OCaml
* [imagelib](https://github.com/rlepigre/ocaml-imagelib)
  * Image loading for OCaml
