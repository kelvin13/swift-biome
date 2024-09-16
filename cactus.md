# The cactus problem

Goal: **Given a (composite) symbol `H.b` of nationality `swift-n` and a current version *`v:d`* of `swift-n`, what is the earliest version of `swift-n` that contains `H.b`?**

## Assumptions 

`swift-n` is a package with branched versioning. 

```
    ●   master:2024-01-06-a
    │
    ●   master:2024-01-05-a
    │
    ●   master:2024-01-04-a
    │
    ●   master:2024-01-03-a
    │   
    │   ●   v1.x:2024-01-06-a
    │   │
    │   │   ●   v1.2:2024-01-06-a
    │   │   │
    │   ├── ●   v1.2:2024-01-05-a
    │   │
    │   ●   v1.x:2024-01-05-a
    │   │
    │   │   ●   v1.1:2024-01-06-a
    │   │   │   
    │   │   ●   v1.1:2024-01-05-a
    │   │   │
    │   ├── ●   v1.1:2024-01-04-a
    │   │
    │   ●   v1.x:2024-01-04-a
    │   │
    │   ●   v1.x:2024-01-03-a
    │   │
    ├── ●   v1.x:2024-01-02-a
    │
    ●   master:2024-01-02-a
    │
    ●   master:2024-01-01-a
    ╎
```

## Case 0

`H.b` is atomic. This is a (comparatively) trivial case, because `H.b` “exists” and therefore has a declaration we can track.

In the following example, `H.b` appeared 3 times:

1.  It was introduced in the *`master`* branch on `2024-01-04-a` (A).
1.  It was introduced in the *`v1.x`* branch on `2024-01-05-a` (B).
1.  It was introduced in the *`v1.1`* branch on `2024-01-04-a` (C).

```
    A   master:2024-01-06-a
    │
    A   master:2024-01-05-a
    │
    A   master:2024-01-04-a
    │
    ×   master:2024-01-03-a
    │   
    │   B   v1.x:2024-01-06-a
    │   │
    │   │   B   v1.2:2024-01-06-a
    │   │   │
    │   ├── B   v1.2:2024-01-05-a
    │   │
    │   B   v1.x:2024-01-05-a
    │   │
    │   │   C   v1.1:2024-01-06-a
    │   │   │   
    │   │   C   v1.1:2024-01-05-a
    │   │   │
    │   ├── C   v1.1:2024-01-04-a
    │   │
    │   ×   v1.x:2024-01-04-a
    │   │
    │   ×   v1.x:2024-01-03-a
    │   │
    ├── ×   v1.x:2024-01-02-a
    │
    ×   master:2024-01-02-a
    │
    ×   master:2024-01-01-a
    ╎
```

Even though `H.b` might have the same mangled name in all four branches, we only consider two snapshots of `H.b` to be the “same” symbol if they share a common ancestor. Therefore: 

*   *`v1.x`* (from `2024-01-05-a`) and *`v1.2`* (all revisions) share the same `H.b`.
*   *`v1.1`* (all revisions) has its own `H.b`, which is independent of identically-named symbols in other branches.
*   *`master`* (from `2024-01-04-a`) has its own `H.b`, which is independent of identically-named symbols in other branches.

So the “earliest” version that contains `H.b` depends on the *current* version we are asking the question “from”. 

## Case 1 

`H.b` is a compound, and its host component has nationality `swift-n`, which is also the nationality of the base component, and the compound itself.

In this case, `H.b` doesn’t “exist”, so we have to compute its life-cycle based on the history of its host and base components, and also the history of the edge relationship between them.

## Case 2

`H.b` is a compound, and its host component has nationality `swift-n`, which is also the nationality of the compound itself. But the base component has nationality `swift-m`. 

This happens, for example, when a local type conforms to a protocol (with foreign extension members) via a local conformance.

In this case, `H.b` doesn’t “exist”, so we have to compute its life-cycle based on the history of its host and base components, and also the history of the edge relationship between them.

The base component lives in a different “multiverse” than the base component and the compound itself.

**The pinned version of `swift-m` can advance, regress, hop branches, and in general *do anything* across versions of `swift-n`.** So the notion of a “rightful heir” to (and by extension, an original ancestor of) a compound symbol is very ill-defined.

## Case 3

`H.b` is a compound, and its base component has nationality `swift-n`, which is also the nationality of the compound itself. But the host component has nationality `swift-m`. 

This happens, for example, when a foreign type conforms to a protocol (with local extension members) via a local conformance.

In this case, `H.b` doesn’t “exist”, so we have to compute its life-cycle based on the history of its host and base components, and also the history of the edge relationship between them.

The host component itself is foreign, but its *history* is local. So there is only one “multiverse” to consider.

## Case 4 

`H.b` is a compound, and both components have foreign nationality.

This happens, for example, when a foreign type retroactively conforms to a protocol (with foreign extension members) via a local conformance. 

> Note: The protocol will always be foreign, because it is not possible for a local protocol to gain foreign extension members that we know about in the current context.

There are up to three “multiverses” to consider: the history of the package vending the base component, the history of the package vending the host component, and the history of the local package (the package vending the conformance).

## Conclusion 

Versioning for Case 0 is already implemented and works well. Versioning for Case 1 and Case 3 is not currently implemented, but could be with some effort. However most compound symbols in the “wild” fall under Case 2, e.g. conformances to `Sequence`, `Collection`, etc.

Versioning for Case 2 and Case 4 is most likely not a tractable problem, because of the number of multiverses (multiple multiverses!) that need to be reconciled to come up with an “answer” to this question.
