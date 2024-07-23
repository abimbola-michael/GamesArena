import 'package:gamesarena/features/app_info/models/app_info.dart';

Map<String, AppInfo> appInfos = {
  "Terms and Conditions": AppInfo(
      name: "Terms and Conditions",
      intro:
          "These Terms and Conditions (\"Terms\") govern your use of the Games Arena mobile application (\"the App\") and the services provided within it. By downloading, installing, or using the App, you agree to comply with and be bound by these Terms. If you do not agree with any part of these Terms, please do not use the App.",
      subInfos: [
        SubInfo(title: "Use of the App", texts: [
          "The App, Games Arena, including its games (Chess, Ludo, Whot, Draught, Xs and Os), is provided for entertainment purposes only.",
          "You must be of legal age in your jurisdiction or have parental consent to use the App."
        ]),
        SubInfo(title: "User Accounts", texts: [
          "To access certain features of the App, you may be required to create a user account.",
          "You are responsible for maintaining the confidentiality of your account information."
        ]),
        SubInfo(title: "Game Rules", texts: [
          "Each game within the Games Arena App adheres to its specific rules, which users are expected to understand and follow.",
          "Any violations of game rules may result in consequences, including but not limited to account suspension or termination."
        ]),
        SubInfo(title: "Fair Play", texts: [
          "Users are expected to engage in fair and sportsmanlike conduct while playing games.",
          "Cheating, exploiting bugs, or engaging in any form of unfair play is strictly prohibited."
        ]),
        SubInfo(title: "User Content", texts: [
          "You may have the option to submit content, such as comments or game-related data.",
          "You retain ownership of your content, but by submitting it, you grant Games Arena a non-exclusive, royalty-free license to use, modify, and display the content."
        ]),
        SubInfo(title: "Privacy", texts: [
          "Your privacy is important to us. Please refer to our Privacy Policy for information on how we collect, use, and disclose your personal information."
        ]),
        SubInfo(title: "Updates and Changes", texts: [
          "Games Arena reserves the right to update, modify, or discontinue the App or any of its games at any time without prior notice."
        ]),
        SubInfo(title: "Limitation of Liability", texts: [
          "Games Arena is not liable for any direct, indirect, incidental, or consequential damages arising out of your use or inability to use the App."
        ]),
        SubInfo(title: "Termination", texts: [
          "Games Arena may terminate your access to the App at any time, with or without cause."
        ]),
        // SubInfo(title: "Governing Law", texts: [
        //   "These Terms are governed by and construed in accordance with the laws of [Your Jurisdiction]."
        // ])
      ],
      outro:
          "By using the Games Arena App, you acknowledge that you have read, understood, and agreed to these Terms and our Privacy Policy. Games Arena reserves the right to update or modify these Terms at any time. It is your responsibility to review these Terms periodically for changes. If you continue to use the App after any modifications, you accept the revised Terms. If you do not agree to the revised Terms, please discontinue your use of the App"),
  "Privacy Policy": AppInfo(
      name: "Privacy Policy",
      intro:
          "Thank you for choosing Games Arena (\"the App\"). This Privacy Policy outlines how we collect, use, and safeguard your personal information.\nLast Updated: 8/1/2024\n By using the App, you agree to the terms outlined in this policy.",
      subInfos: [
        SubInfo(title: "Information We Collect", texts: [
          "User Account Information: When you create an account, we may collect your username, email address, and other relevant information.",
          "Game Data: We collect data related to your gameplay, scores, and interactions within the App.",
          "Device Information: We may collect information about your device, including device type, operating system, and unique identifiers.",
          "Log Data: Our servers automatically record information when you use the App, including IP address, browser type, and the date and time of your request."
        ]),
        SubInfo(title: "How We Use Your Information", texts: [
          "Provide and Improve the App: We use your information to deliver and enhance the functionality of the App.",
          "Personalization: Your data may be used to personalize your experience within the App.",
          "Communications: We may use your email address to send important updates, newsletters, or promotional materials."
        ]),
        SubInfo(title: "Data Sharing", texts: [
          "Third-Party Services: We may share data with third-party service providers to facilitate App functionality.",
          "Legal Compliance: We may disclose your information in response to legal requests or to protect our rights and interests."
        ]),
        SubInfo(title: "Your Choices", texts: [
          "Account Settings: You can manage your account settings and preferences within the App.",
          "Communication Preferences: You have the option to opt-out of promotional communications."
        ]),
        SubInfo(title: "Security", texts: [
          "We implement security measures to protect your information, but no method of transmission over the internet is 100% secure."
        ]),
        SubInfo(title: "Children’s Privacy", texts: [
          "The App is not intended for individuals under the age of 13. We do not knowingly collect personal information from children."
        ]),
        SubInfo(title: "Changes to this Privacy Policy", texts: [
          "We may update this Privacy Policy periodically. The date at the top of the policy indicates the last revision. Please review the policy regularly."
        ]),
        SubInfo(title: "Contact Us", texts: [
          "If you have any questions or concerns about this Privacy Policy, please contact us at abimbolamichael100@gmail.com or call 07038916545 for further assistance."
        ]),
      ],
      outro:
          "By using the Games Arena App, you agree to the terms of this Privacy Policy. If you do not agree with this policy, please refrain from using the App.\nLast Updated: 8/1/2024\nThank you for trusting Games Arena with your information."),
  "About Us": AppInfo(
      name: "About Us",
      intro:
          "Welcome to Games Arena, where the thrill of gaming meets a world of endless entertainment. At Games Arena, we are passionate about creating a gaming experience that captivates, challenges, and brings joy to players of all ages.",
      subInfos: [
        SubInfo(title: "Our Mission", texts: [
          "At the core of Games Arena is a commitment to providing a diverse range of high-quality games that cater to different tastes and preferences. Our mission is to be your go-to destination for fun and engaging gaming experiences."
        ]),
        SubInfo(title: "What Sets Us Apart", texts: [
          "Variety of Games: From the classic strategy of Chess to the excitement of Ludo, the tactical moves in Draught, the unpredictability of Whot, and the timeless fun of Xs and Os, we offer a diverse selection of games to keep you entertained.",
          "User-Focused Design: We prioritize user experience, ensuring our games are not only challenging but also easy to navigate. Whether you're a seasoned player or a newcomer, Games Arena is designed with you in mind.",
          "Community Engagement: We believe that gaming is not just about playing; it's about connecting. Join our community, share your achievements, and challenge friends to friendly matches. The Games Arena community is a place where gamers come together."
        ]),
        SubInfo(title: "Our Team", texts: [
          "Games Arena is driven by a team of dedicated individuals who share a love for gaming. From developers crafting immersive gameplay to support staff ensuring a smooth experience, our team works collaboratively to bring you the best gaming platform."
        ]),
        SubInfo(title: "Contact Us", texts: [
          "We value your feedback and are here to assist you. If you have any questions, suggestions, or just want to share your gaming experiences, feel free to reach out to us at abimbolamichael100@gmail.com or call 07038916545 for further assistance."
        ]),
      ],
      outro: "Thank you for choosing Games Arena. Let the games begin!"),
};
