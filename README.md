# Join: 找夥伴

<p align="middle">
  <image src="https://user-images.githubusercontent.com/63045187/208042063-1787d017-9688-42f8-8ce9-9c325810eaaa.png" width="160"/>
</p>

<p align="center">
Join: 找夥伴(Finding Partners) is an app that enables you to share your ideas and find collaborators, showcase your skills and portfolios, and start a one-on-one chat or create a group chat with project team members.
</p>

<p align="middle">
    <img src="https://img.shields.io/badge/platform-iOS-blue">
    <img src="https://img.shields.io/badge/release-v1.1.3-green">
    <img src="https://img.shields.io/badge/License-MIT-yellow">
</p>

<p align="middle">
    <a href="https://apps.apple.com/tw/app/join-%E6%89%BE%E5%A4%A5%E4%BC%B4/id6444241975?l=en"><img src="https://i.imgur.com/NKyvGNy.png"></a>
</p>

## Tables
- [Features](#features)
    - Create Personal Profile and Portfolio
    - Find Ideas
    - Find Partners
    - Communicate and Collaborate
- [Techniques](#techniques)
- [Setup the Project](#setup-the-project)
- [Libraries](#libraries)
- [Credit](#credit)
- [Version](#version)
- [Release Notes](#release-notes)
- [Author](#author)
- [License](#license)

## Features

### Create Personal Profile and Portfolio
- Edit personal information, including a summary and all the techniques you equipped.
- Provide your interests. The app will recommend you the projects that fit your interests.
- Enrich your portfolio by uploading images, scan substantial works and convert them into images, or paste the url of your works to show what you've made.

<p align="middle">
  <image src="https://user-images.githubusercontent.com/63045187/208041190-fd415342-b5f6-4ec3-9e02-bdd30eb73541.png" width="440"/>
</p>

### Find Ideas
- Find great ideas that you're interested in or fit with your skills.
- Contact with the project contact to ask about the details.
- Apply for the position right away and track what projects you've applied for.
- Saved the projects you're interested in, and read them again afterward.

<p align="middle">
  <image src="https://user-images.githubusercontent.com/63045187/208279156-3abd32c8-fbdb-491d-8a90-c8a2ed8b2c22.png" width="440"/>
</p>

### Find Partners
- Post your ideas and the skills you need to fulfill the idea to find the one that fit with the position.
- Bind your team with your projects.
- Track who had applied for your projects.
- Accept application to join a new member into your group.

<p align="middle">
  <image src="https://user-images.githubusercontent.com/63045187/208041371-64ccac79-59d5-4419-8553-187ab0056d86.png" width="440"/>
</p>

### Communicate and Collaborate
- Send, receive and accept friend requests from the community of Join: 找夥伴.
- Start a one-on-one chat with strangers or your friends.
- Create a group chatroom with your friends and communicate with a whole team.
- Establish a working group chatroom based on your team instantly.

<p align="middle">
  <image src="https://user-images.githubusercontent.com/63045187/208279158-2bcd5973-39d6-4a09-b7ab-7b04b1c23adb.png" width="440"/>
    <image src="https://user-images.githubusercontent.com/63045187/208279162-a925fb1a-4d24-4a29-85c3-3743e9e761d3.png" width="440"/>
</p>

## Techniques

- Fetched web preview images and created rich links through **LinkPresentation**.
- Scanned documents and converted them into images using **VisionKit**.
- Created photos uploading feature using **PhotoKit**.
- Ensured data assembled correctly with **GCD** and prevented race condition with **NSLock**.
- Achieved flexible UI and easily identifiable data combined with cells using **UICollectionViewDiffableDatasource** and **UITableViewDiffableDatasource**.
- Managed data with **Firebase SDK** including **Cloud Firestore** and **Storage**, obtained real-time messages by adding listeners to Firestore documents.
- Implemented **Sign-in with Apple** and **Firebase Authentication** to offer customized service and data management. 
- Reused views and cells with **Xib** and Storyboard to avoid duplicated code.
- Manipulated button state automaically by **UIButtonConfiguration**.
- Constructed clean project through **MVC** design patterns.

## Setup Project

The project didn't include the "GoogleService-Info.plist" file for Firebase service, as well as the p8 file and the keys needed for Sign-in with Apple. Thus, if you want to build the project on your own machine, you'll need to add those files into the project.

1. Clone the project to local

    ```
    git clone https://github.com/Rileydk/Join.git
    ```

2. Go to Firebase, create a new project, add the generated GoogleService-Info.plist under "Join/Resources" directory of the project, then create Firestore inside your Firebase project.

3. Go to your Apple Developer account, generate a p8 file through register a new key for sign-in with apple.

4. Add the p8 file under "Join/Resources/AppleAuth" directory of the project.

5. Add a "AppleAuthConfig" file, then add content below to the file:

    ```swift
    import Foundation

    enum AppleAuthConfig: String, Encodable {
        case p8KeyID = <p8 Key ID>
        case teamID = <Your Team ID>
        case bundleID = <Bundle ID>
        case privateKeyFileName = <p8 File Name>
    }
    ```

## Libraries

- [Firebase SDK](https://github.com/firebase/firebase-ios-sdk)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftJWT](https://github.com/Kitura/Swift-JWT)
- [IQKeyboardManagerSwift](https://github.com/hackiftekhar/IQKeyboardManager)
- [Lottie](https://github.com/airbnb/lottie-ios)
- [JGProgressHUD](https://github.com/JonasGessner/JGProgressHUD)
- [MJRefresh](https://github.com/CoderMJLee/MJRefresh)

## Credit

Some of the icons used in this app was made by authors listed below and was downloaded from [Flaticon](https://www.flaticon.com/) :
- [Pixel perfect](https://www.flaticon.com/authors/pixel-perfect)
- [Freepik](https://www.freepik.com) 
- [Kirill Kazachek](https://www.iconfinder.com/kirill.kazachek)
- [Bamicon](https://www.flaticon.com/authors/bamicon)
- [kmg design](https://www.flaticon.com/authors/kmg-design)

## Version

> 1.1.3

## Release Notes

| Version       | Date          | Note          |
| ------------- |:-------------:| ------------- |
| 1.1.0         | 2022/12/03    | First released on App Store. |
| 1.1.3         | 2022/12/08    | Added new features and improve UI. |

## Requirements

- iOS 15.0+
- Swift 5
- Xcode 13.4.1+

## Author

Riley Lai | <dakimi07@gmail.com>

## License

Join: 找夥伴 is released under the MIT license. See [LICENSE](https://github.com/Rileydk/Join/blob/7ddd4a4412fbb4a8b7545e4fe5f91f20c478b4c1/LICENSE) for details.


