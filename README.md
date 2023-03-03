# CoalZig
## An Implementation of the CoalStar Engine in Zig
___

### *At a Glance: CoalStar Engine Goals* 

#### Primary goals of CoalStar:

* Massive contiguous overworld that can span many thousands, tens, or even hundreds of thousands of units without losing precision
* Highly compressed design of world data to have as small an installation cost as possible
* Streamlined and threaded design of world assets and data to allow for relatively fast in-game traversal
* In-engine editing, to prevent messy and convoluted tooling

#### Secondary goals of CoalStar:

* Portalized projections of dimensional arrangements for internal spaces
* Focused in-engine player character movement based around responsive and expected results between input and output
* ProcGen of mundane assets, with manual override tables to decrease time of development and reduce size of installation
* External (LUA) script integration to help accelerate development through an easy-to-use and well documented scripting system

#### Tertiary goals of CoalStar are:

* Seasonal, Environmental, and Economic simulation
* Player manipulation of terrain and static objects in-game
* Externalized asset loading and user-defined override tables for mod support


### *What is CoalStar?*

  The CoalStar Game Engine is an in-development 3D video game engine project. The goals of the engine are a supermassive openworld, with seamlessly traversable landforms much larger than seen in the current market. As well, an emphasis is placed on first or third person player movement and interactions, creating a less rigid engagement with the worldspace as a whole. The ideal complete form is an an open world environment that players can fully explore and engage with, without the necessary macro/micro scaling necessary in current implementations.

  CoalStar is being developed using the Simple DirectMedia Layer Library and GL Extension Wrangler. It is built on --and with the idea of-- low-powered hardware, and is designed within the philosophy of widespread adoptability over finer visual detail. Should a decision require either exclusively, the former will be chosen.

  The visual worldspace is produced by a method of dimensional projection. Each 1024x1024 unit chunk (sometimes referred to as 'tile') is projected from the current perspective based on its associated difference in dimensional coordinates. In-dimensional floating point coordinates do not exceed +-512.0 units, keeping precision of minute vertex positions high. Internally, a base position for an entity is stored as an integral packed value, using rounding as a free ride to handle interdimensional coordinate changes. 

  Chunks are given an additional address for *intra*dimensional travel. Caves, building interiors, and other such pocket-spaces will exist at various dimensional Z-offsets. Intradimensional traversal will occur through portals which will perform an interpretation of position, rotation, and velocity. Interdimensional traversal will be facilitated in these pocket-spaces to allow the space to lie appropriately on the edge of dimensions. Nested intra and inter dimensional travel will allow for the collapsing or expansion of overworld space and facilitate the creation of impossible spaces, which everyone enjoys.

  CoalStar is being built and designed around, and to facilitate development of, an as of yet unnamed game project. The game project will have more information released in the future as development continues. A demonstration of the builds may be [found here](https://coalnova.github.io/links/), at a very outdated development blog.


### *Why Zig?*

  Initially the project had been developed in C++. This had worked fine, but certain issues began to crop up regarding readability of some headier functions, as well as tracking down some more confusing bugs that had arisen. Though a few newer languages exist that could facilitate this, I eventually fell for Zig for its coalescing of C, which the SDL library is written in.
