# Dicey 🎲

Dicey is a robust, on-device TTRPG designer and Game Master support tool built with SwiftUI. It goes beyond simple dice rolling by offering a powerful Monte Carlo simulation engine to calculate probability distributions, percentiles, and success rates for complex dice pools. 

While Dicey is available on the App Store for a small one-time fee to help cover development and maintenance costs, the entire source code is completely open-source. You are highly encouraged to explore, fork, and use the code to build your own tools!

## ✨ Features

* **Comprehensive Dice Support:** Roll standard polyhedral dice including d4, d6, d8, d10, d12, d20, and d100.
* **Advanced Dice Mechanics:**
    * **Exploding Dice:** Chain explosive rolls up to 10 times.
    * **Reroll Behaviors:** Automatically reroll 1s or reroll results below a custom threshold.
    * **Keep/Drop:** Keep the highest or lowest 'N' dice from your pool.
* **Success Conditions:** Set complex target conditions such as "Sum meets/over target," "Sum below Target," or count occurrences of a specific face.
* **Monte Carlo Simulation Engine:** Runs up to 20,000 iterations in the background to instantly estimate average yields, standard deviations, and success probabilities.
* **Visual Data & Comparison:** Save configuration snapshots and compare their probability distributions side-by-side using smooth overlay charts.
* **Roll History:** Keeps a detailed ledger of your recent rolls, including the exact mechanics used, success states, and modifiers.

## 💻 Tech Stack & Requirements

* **Framework:** 100% SwiftUI.
* **Architecture:** MVVM utilizing Combine and `@MainActor` for thread-safe background calculations.
* **Visuals:** Utilizes Apple's native `Charts` framework (requires iOS 16.0+ for full distribution chart features, includes minimal text fallback for older versions).

## 🚀 Installation & Usage

1. Clone the repository.
2. Open `Dicey.xcodeproj` in Xcode 14 or later.
3. Build and run on your iOS Simulator or physical device.

## 📄 License

**MIT License**

Copyright (c) 2026 Zhi Zheng Yeo 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
