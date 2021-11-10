# URLSessionBackport

<p align="center">
<a href="https://swiftpackageindex.com/mochidev/URLSessionBackport">
<img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmochidev%2FURLSessionBackport%2Fbadge%3Ftype%3Dswift-versions" />
</a>
<a href="https://swiftpackageindex.com/mochidev/URLSessionBackport">
<img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmochidev%2FURLSessionBackport%2Fbadge%3Ftype%3Dplatforms" />
</a>
<a href="https://github.com/mochidev/URLSessionBackport/actions?query=workflow%3A%22Test+URLSessionBackport%22">
<img src="https://github.com/mochidev/URLSessionBackport/workflows/Test%20URLSessionBackport/badge.svg" alt="Test Status" />
</a>
</p>

`URLSessionBackport` aims to make it possible to use URLSession's new async/await syntax on older OSs, namely iOS 13 or macOS 10.15 and newer. Note that Xcode 13.2 is required, as that version contains the necessary back-ported async/await libraries.

## Installation

Add `URLSessionBackport` as a dependency in your `Package.swift` file to start using it. Then, add `import URLSessionBackport` to any file you wish to use the library in.

Please check the [releases](https://github.com/mochidev/URLSessionBackport/releases) for recommended versions.

```swift
dependencies: [
    .package(url: "https://github.com/mochidev/URLSessionBackport.git", .upToNextMinor(from: "1.0.0")),
],
...
targets: [
    .target(
        name: "MyPackage",
        dependencies: [
            "URLSessionBackport",
        ]
    )
]
```

## What is `URLSessionBackport`?

`URLSessionBackport` adds a single property to your `URLSession` instances: `.backport`. The best part? Within this namespace, URLSession's async/await methods have been magically re-implemented, allowing you access to them on iOS 13 or macOS 10.15 and newer! Additionally, the methods are automatically marked as deprecated, so they'll let you know when it's safe to remove them.

## Contributing

Contribution is welcome! Please take a look at the issues already available, or start a new issue to discuss a new feature. Although guarantees can't be made regarding feature requests, PRs that fit with the goals of the project and that have been discussed before-hand are more than welcome!

Please make sure that all submissions have clean commit histories, are well documented, and thoroughly tested. **Please rebase your PR** before submission rather than merge in `main`. Linear histories are required.
