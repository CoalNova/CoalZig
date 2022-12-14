# CoalZig
### A reimplementation of the CoalStar/CoalSpark engine in Zig
___


#### *What is CoalStar?*

The CoalStar Game Engine is an in-development 3D video game engine project. The goals of the engine are a supermassive openworld, with seamlessly traversable landforms much larger than seen in the current market. As well, an emphasis is placed on first or third person player movement and interactions, creating a less rigid engagement with the worldspace as a whole. The ideal complete form is an an open world environment that players can fully explore and engage with, without the necessary macro/micro scaling necessary in current implementations.

CoalStar is being developed using the Simple DirectMedia Layer Library and GL Extension Wrangler. It is built on --and with the idea of-- low-powered hardware, and is designed within the philosophy of widespread adoptability over finer visual detail. Should a decision require either exclusively, the former will be chosen.

Primary goals of CoalStar:

* Massive contiguous overworld that can span many thousands, tens, or even hundreds of thousands of units without losing precision
* Highly compressed design of world data to have as small an installation cost as possible
* Streamlined and threaded design of world assets and data to allow for relatively fast in-game traversal

Secondary goals of CoalStar:

* Portalized projections of dimensional arrangements for internal spaces
* Focused in-engine player character movement based around responsive and expected results between input and output
* ProcGen of mundane assets, with manual override tables to decrease time of development and reduce size of installation
* External (LUA) script integration to help accelerate development through an easy-to-use and well documented scripting system

Tertiary goals of CoalStar are:

* Seasonal and Environmental support
* Player manipulation of terrain and static objects
* Externalized asset loading and user-defined override tables for mod support

CoalStar is designed to facilitate development of an adjoining, as yet unnamed game project. The game project will have more information released in the future. A demonstration of the builds may be [found here](https://coalnova.github.io/links/), at a very outdated development blog.


#### *What is CoalSpark?*

CoalSpark is a 'lite' version of the engine which focuses on rapid development as a proof of concept for the systems that will be in CoalStar. It utilizes entirely 2D, software-driven render pipeline. It will allow for proofing of behaviors and mechanical concepts. Many elements will not be testable in the environment, but the codebase once finished should be migratable over to the full system.


#### *Why Zig?*

Initially the project had been developed in C++. This had worked fine, but certain issues began to crop up regarding readability of some headier functions, as well as tracking down some more confusing bugs that had arisen. Though a few newer languages exist that could facilitate this, I eventually fell to Zig
for its coalescing of C, which the SDL library is written in.
