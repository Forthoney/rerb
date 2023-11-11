The best way to describe WERB's capabilities and boundaries is by explaining what it is versus what it is not.
## WERB is a _developer_'s tool, not a client-side package
WERB is meant to be used by the developer to help them write code. It is not meant to be shipped to the client as an npm package.
There are a couple of reasons behind this.
1. Implementation Difficulty

It is very difficult to ship Gems with Ruby on WASM. This problem holds for almost all popular interpreted languages that have some WASM implementation at the moment (e.g. pip and python). 
It may be possible in a year or two to include Gems written in pure Ruby with a RubyVM running on WASM. 
Unfortunately, WERB uses [better-html](https://github.com/Shopify/better-html), a Gem with C extensions, and these Gems will likely take longer to be shippable.

2. Practical Considerations

Even if a means to ship WERB to the client is developed, we should stop and ask - _should we?_ 
Sending WERB over to the client would mean a larger download size for the client. 
This may not seem like a huge issue, but considering the base Ruby Interpreter is already fairly large, it's good to save space where possible.
There have been precedents of adding libraries increasing the WASM download size significantly, namely in Blazor WebAssembly.

## WERB is an ERB Compiler, not a full UI Library/Framework
At this current stage, WERB is not concerned with efficient re-rendering algorithms, components, or other features that libraries like React have.
It is concerned with transforming easy-to-write ERB files into tedious DOM transformations.
Once WERB finishes compilation, how exactly the rendering works is in the developer's hands.
If you choose to rerender the entire page on every update, that is up to you. 
If you choose a more fine grained, element-wise rerendering, that is also up to you.
If you choose to build a library that extends upon WERB's output and applies a generalizable rerendering technique, that is also entirely up to you.
The best parallel would be JSX, where JSX does not inherently impose anything about how things should be rendered and rerendered, but enables developers to write DOMs succinctly.
