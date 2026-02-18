# 🎓 Eduktok - Language Learning Made Interactive

Eduktok is a language learning iOS app similar to Rosetta Stone, designed to make learning interactive and engaging. Built with Swift and SwiftUI, it offers users an intuitive platform to master new languages through visual learning, listening comprehension, and speech practice.

**📱 Download from App Store**: https://lnkd.in/eQCHw6Q3  
**🌎 Available in**: Canada and USA

## ✨ Features
- **📚 Interactive Lessons**: Learn through visual association and context
- **🎧 Listening Comprehension**: Audio-based exercises in multiple languages
- **🗣️ Speech Recognition**: Practice pronunciation with real-time feedback
- **📊 Progress Tracking**: Monitor your learning journey
- **🏆 Gamified Learning**: Unit-based progression system
- **🌍 Multilingual Support**: English, Spanish, and more languages

## 🎯 Project Status

**Current Version**: Live on App Store  
**Next Version Goal**: 30 units × 15 lessons = 450 total lessons

### What's New:
- ✅ Improved database layer with comprehensive error handling
- ✅ Image management infrastructure for Cloudflare R2
- ✅ Automated deployment scripts
- ✅ Complete content creation documentation
- ✅ Production-ready workflow for scaling content

## 🎬 Demo

https://github.com/user-attachments/assets/36ccc22d-7949-4f94-8099-955d767b28ff  

https://github.com/user-attachments/assets/a33cef2a-9bf6-43dc-8a5e-6867fc494f49

<img width="1440" alt="macEduktok" src="https://github.com/user-attachments/assets/ebbad7da-b19f-4046-92e7-965e33cfeb93" />

## 🏗️ Architecture

**Platform**: iOS (Swift/SwiftUI)  
**Backend**: Firebase (Firestore + Storage)  
**CDN**: Cloudflare R2 (for images and audio)  
**Languages**: English, Spanish (more coming soon)

### Tech Stack:
- SwiftUI for modern, declarative UI
- Firebase Firestore for real-time data
- AVFoundation for audio playback
- Speech Recognition API for pronunciation practice
- Combine for reactive programming

## 🚀 Getting Started

### For Development

1. **Clone the repository**:
```bash
git clone https://github.com/yunior123/eduktok.git
cd eduktok
```

2. **Open in Xcode**:
```bash
open eduktok.xcodeproj
```

3. **Configure Firebase**:
   - Add your `GoogleService-Info.plist`
   - Update Firebase configuration

4. **Build and Run**:
   - Select target device/simulator
   - Press ⌘+R to run

### For Content Creation

**📖 Start here**: Read [QUICK_START.md](QUICK_START.md) for complete guide

**Quick steps**:
1. Install tools: `npm install -g wrangler firebase-tools`
2. Review structure: See [CONTENT_STRUCTURE.md](CONTENT_STRUCTURE.md)
3. Use template: Follow [examples/unit-01-detailed.md](examples/unit-01-detailed.md)
4. Create images: Place in `app-images/unit-XX/lesson-YY/`
5. Upload: Run `./scripts/upload-to-r2.sh`
6. Import: Use Firebase CLI or Console

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | Complete guide to start creating content |
| [claude.md](claude.md) | Full project context and architecture |
| [CONTENT_STRUCTURE.md](CONTENT_STRUCTURE.md) | Outline of all 30 units (450 lessons) |
| [examples/unit-01-detailed.md](examples/unit-01-detailed.md) | Detailed template for Unit 1 |
| [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) | Recent improvements and status |
| [app-images/README.md](app-images/README.md) | Image guidelines and requirements |
| [scripts/README.md](scripts/README.md) | Script documentation and usage |

## 🛠️ Project Structure

```
eduktok/
├── eduktok/                    # Main app source
│   ├── db/                     # Database layer
│   ├── models/                 # Data models
│   ├── views/                  # SwiftUI views
│   ├── view_models/            # View models
│   └── utils/                  # Utility functions
├── app-images/                 # Image assets (organized by unit/lesson)
├── scripts/                    # Deployment and generation scripts
├── examples/                   # Content creation templates
└── docs/                       # Documentation
```

## 🎯 Content Creation Workflow

```
Plan → Create Images → Upload to R2 → Generate JSON → Import to Firebase → Test
```

See [QUICK_START.md](QUICK_START.md) for detailed workflow.

## 🧪 Testing

Run tests in Xcode:
```bash
# Unit tests
⌘+U

# UI tests
⌘+U (select UI tests scheme)
```

## 📦 Deployment

### For App Store Release:
1. Update version in Xcode
2. Archive build (Product → Archive)
3. Upload to App Store Connect
4. Submit for review

### For Content Updates:
1. Create/update content locally
2. Upload images: `./scripts/upload-to-r2.sh`
3. Import to Firebase
4. Content updates automatically via Firebase

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📈 Roadmap

### Version 2.0 (In Progress)
- [ ] 30 units with 15 lessons each (450 total)
- [ ] Enhanced image quality with Cloudflare R2
- [ ] Improved lesson variety
- [ ] Better pronunciation feedback

### Future Versions
- [ ] More languages
- [ ] Offline mode
- [ ] Adaptive learning paths
- [ ] Social features
- [ ] Achievement system
- [ ] Tablet optimization

## 🐛 Known Issues

See [GitHub Issues](https://github.com/yunior123/eduktok/issues) for current bugs and feature requests.

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## 👥 Team

**Creator**: Yunior Rodriguez Osorio  
**GitHub**: [@yunior123](https://github.com/yunior123)

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- Cloudflare for CDN services
- Swift and SwiftUI community
- All beta testers and early users

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yunior123/eduktok/issues)
- **Email**: [Contact via GitHub profile](https://github.com/yunior123)
- **App Store**: [Leave a review](https://lnkd.in/eQCHw6Q3)

---

**Made with ❤️ for language learners everywhere**
