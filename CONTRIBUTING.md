# Contributing to Our Heart

First off, thank you for considering contributing to **Our Heart**! It's people like you that make this private relationship companion better for everyone.

> 💕 This project is built with love and respects user privacy above all else.

## Code of Conduct

By participating, you agree to maintain a respectful, inclusive, and harassment‑free environment for everyone.

## How Can I Contribute?

### Reporting Bugs

- **Check existing issues** first to avoid duplicates.
- Use the **Bug Report** template (if available) and include:
  - Device model and Android version
  - Flutter version (`flutter --version`)
  - Steps to reproduce
  - Expected vs. actual behavior
  - Screenshots or screen recordings (if safe and relevant)

### Suggesting Enhancements

- Open a **Feature Request** issue.
- Describe the problem you're solving and your proposed solution.
- Keep in mind the app's core principle: **offline‑first, local privacy**.

### Pull Requests

1. **Fork the repository** and create your branch from `main`.
2. **Follow the code style** – we use `flutter analyze --fatal-infos` and `dart format`.
3. **Write clear commit messages** (Conventional Commits are encouraged).
4. **Test your changes** – run the app on a physical device or emulator.
5. **Open a Pull Request** against the `main` branch.

## Development Setup

### Prerequisites

- Flutter 3.x stable
- Android Studio / VS Code with Flutter extensions
- Android SDK (API 21+)

### Getting Started

```bash
git clone https://github.com/lelextb/our_heart.git
cd our_heart
flutter pub get
flutter run
```

### Project Structure

- `lib/features/` – Feature modules (auth, home, gallery, lyric_video, …)
- `lib/core/` – Shared constants, themes, utilities
- `lib/data/` – Drift database, repositories, local storage
- `lib/shared_widgets/` – Reusable glassmorphic components

### Code Style

- Run `dart format .` before committing.
- Run `flutter analyze` – there should be **0 warnings**.
- Use meaningful variable/function names.
- Prefer **BLoC/Cubit** for state management inside features.

### Commit Messages

We recommend [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add custom glass color picker
fix: correct lyric sync after seeking
docs: update README with new screenshots
refactor: extract heart clipper to separate file
```

## Building & Testing

### Run all tests

```bash
flutter test
```

### Build APK (debug)

```bash
flutter build apk --debug
```

### Build release APK (requires keystore)

```bash
flutter build apk --release --split-per-abi
```

## Licensing

By contributing, you agree that your contributions will be licensed under the **MIT License**.

---

## ❤️ Thank You!

Your contributions help keep love stories alive — offline and private.

If you have any questions, feel free to open an issue or reach out.
