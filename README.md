# maybeuninit

This is a userlevel implementation of the `undefined` keyword in Zig.<br>
It is inspired by [MaybeUninit](https://doc.rust-lang.org/stable/core/mem/union.MaybeUninit.html) in Rust.

## Minimum supported `Zig`
`0.3+`

This version will be tested in CI and may only be bumped in new minor versions. Any changes to the support minimum will be called out in the release notes.

## Recent changes
 * 0.2
    * Change the definition of `MaybeUninit` from `packed union` to `extern union`, due to `packed union`'s setting the alignment always to 1.
 * 0.1
    * Initial library setup

## Issues
At the point of writing, it is impossible to create an uninitialized `MaybeUninit(T)`, and later initialize it at compiletime.<br>
This is an issue of the compiler, which tracks the current active field of packed and extern unions when used at compiletime, while it shouldn't.<br>
The issue is reported to the Zig compiler, and can be followed [here](https://github.com/ziglang/zig/issues/3134).