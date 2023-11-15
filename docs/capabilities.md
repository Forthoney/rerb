# What does RERB want to be?
In short, RERB roughly mirrors how [React deals with JSX](https://facebook.github.io/jsx/). 
Firstly, it borrows the principle that JSX is merely syntactic sugar over JS, and thus is not valid ECMAScript. JSX is instead precompiled by Babel into valid JS.
Secondly, JSX is only one part of React, and a part that is unrelated to how components are updated. JSX is just an easy way to describe a DOM in code.

The long answer is the following:
## RERB is a _developer_'s tool, not a client-side package
RERB is meant to be used by the developer to help them write code. It is not meant to be shipped to the client as an npm package.
There are a couple of reasons behind this.
1. Implementation Difficulty

It is currently very difficult to ship Gems with Ruby on WASM. This problem holds for almost all popular interpreted languages that have some WASM implementation at the moment (e.g. pip and python). 
It may be possible in a year or two to include Gems written in pure Ruby with a RubyVM running on WASM. 
Unfortunately, RERB uses [better-html](https://github.com/Shopify/better-html), a Gem with C extensions, and these Gems will likely take longer to be shippable.

2. Practical Considerations

Even if a means to ship RERB to the client is developed, we should stop and ask - _should we?_ 
Sending RERB over to the client would mean a larger download size for the client. 
This may not seem like a huge issue, but considering the base Ruby Interpreter is already fairly large, it's good to save space where possible.
There have been precedents of adding libraries increasing the WASM download size significantly, namely in Blazor WebAssembly.

## RERB is an ERB Compiler, not a full UI Library/Framework
At this current stage, RERB is not concerned with efficient re-rendering algorithms, components, or other features that libraries like React have.
It is concerned with transforming easy-to-write ERB files into tedious DOM transformations.
Once RERB finishes compilation, how exactly the rendering works is in the developer's hands.
If you choose to rerender the entire page on every update, that is up to you. 
If you choose a more fine grained, element-wise rerendering, that is also up to you.
If you choose to build a library that extends upon rerb's output and applies a generalizable rerendering technique, that is also entirely up to you.
This philosophy may change in the future, but RERB's current priority is in describing a DOM with erb, not DOM update algorithms.

# Where is RERB currently?
## Features
RERB supports the vast majority of HTML deemed valid by the better-html Gem. There are some small pieces which are unsupported, none of which are significant
- [ ] Strip from beginning or end of String via `<%-` and `-%>` (currently ignored entirely)
- [ ] Attribute values without quotation marks (currently undefined behavior)

## Rigidity
RERB is quite brittle at the moment, and there are ongoing efforts to help make it more "error tolerant".
- [ ] Attempting to commpile invalid HTML-ERB results in undefined behavior. It may error, or it may finish running and produce the wrong graph.
- [ ] Improve better-html's Parser's output type.
- [ ] More tests, particularly for the CLI.
