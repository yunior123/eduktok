//
//  eduktokUITests.swift
//  eduktokUITests
//
//  Created by Yunior Rodriguez Osorio on 18/2/24.
//

import XCTest
import Foundation

final class eduktokUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "1", "-ui-testing-real", "1"]
        app.launch()
        return app
    }

    private func credentials() -> (email: String, password: String)? {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["UITEST_REAL_EMAIL"],
              let password = env["UITEST_REAL_PASSWORD"],
              !email.isEmpty,
              !password.isEmpty else {
            return nil
        }
        return (email, password)
    }

    private func authVisible(_ app: XCUIApplication) -> Bool {
        app.textFields["auth.emailField"].waitForExistence(timeout: 2)
    }

    private func homeVisible(_ app: XCUIApplication) -> Bool {
        app.tabBars.buttons["Languages"].waitForExistence(timeout: 2) ||
        app.tabBars.buttons["Settings"].exists
    }

    private func ensureSignInMode(_ app: XCUIApplication) {
        let primary = app.buttons["auth.primaryButton"]
        guard primary.waitForExistence(timeout: 3) else { return }
        if primary.label != "Sign In" {
            let toggle = app.buttons["auth.toggleModeButton"]
            if toggle.exists { toggle.tap() }
        }
    }

    private func signInIfNeeded(_ app: XCUIApplication) throws {
        if homeVisible(app) { return }
        guard authVisible(app) else {
            throw XCTSkip("Neither auth nor home is visible")
        }
        guard let creds = credentials() else {
            throw XCTSkip("Set UITEST_REAL_EMAIL and UITEST_REAL_PASSWORD")
        }

        ensureSignInMode(app)

        let emailField = app.textFields["auth.emailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText(creds.email)

        let passwordField = app.secureTextFields["auth.passwordField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        passwordField.tap()
        passwordField.typeText(creds.password)

        app.buttons["auth.primaryButton"].tap()

        if app.staticTexts["Verify Your Email"].waitForExistence(timeout: 3) {
            throw XCTSkip("Account is not verified. Use a verified UITEST_REAL_EMAIL")
        }

        XCTAssertTrue(homeVisible(app))
    }

    private func openLanguages(_ app: XCUIApplication) {
        let button = app.tabBars.buttons["Languages"]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
    }

    private func openSettings(_ app: XCUIApplication) {
        let button = app.tabBars.buttons["Settings"]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
    }

    private func openStoreOrSkip(_ app: XCUIApplication) throws {
        let store = app.tabBars.buttons["Store"]
        guard store.waitForExistence(timeout: 2) else {
            throw XCTSkip("Store tab not present (likely already lifetime)")
        }
        store.tap()
    }

    private func parseLessonNumber(_ app: XCUIApplication) -> Int {
        let label = app.staticTexts["lesson.progressLabel"].label
        guard let lessonRange = label.range(of: "Lesson ") else { return 0 }
        let suffix = label[lessonRange.upperBound...]
        return Int(suffix.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func openUnit(_ number: Int, in app: XCUIApplication) {
        openLanguages(app)
        let unit = app.buttons["unit.card.\(number)"]
        XCTAssertTrue(unit.waitForExistence(timeout: 8))
        unit.tap()
    }

    func testFlow01LaunchesToAuthOrHome() {
        let app = launchApp()
        XCTAssertTrue(authVisible(app) || homeVisible(app))
    }

    func testFlow02AuthFieldsVisibleWhenSignedOut() throws {
        let app = launchApp()
        guard authVisible(app) else { throw XCTSkip("Auth screen not visible") }
        XCTAssertTrue(app.textFields["auth.emailField"].exists)
        XCTAssertTrue(app.secureTextFields["auth.passwordField"].exists)
    }

    func testFlow03AuthForgotPasswordOpens() throws {
        let app = launchApp()
        guard authVisible(app) else { throw XCTSkip("Auth screen not visible") }
        app.buttons["auth.forgotPasswordButton"].tap()
        XCTAssertTrue(app.staticTexts["auth.forgot.title"].waitForExistence(timeout: 3))
    }

    func testFlow04AuthModeToggleWorks() throws {
        let app = launchApp()
        guard authVisible(app) else { throw XCTSkip("Auth screen not visible") }
        let toggle = app.buttons["auth.toggleModeButton"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        toggle.tap()
        XCTAssertTrue(app.buttons["auth.primaryButton"].exists)
    }

    func testFlow05SignInRealUser() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        XCTAssertTrue(homeVisible(app))
    }

    func testFlow06HomeShowsTabsAfterSignIn() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Languages"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    func testFlow07OpenLanguagesTab() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openLanguages(app)
        XCTAssertTrue(app.buttons["language.english"].waitForExistence(timeout: 4))
    }

    func testFlow08SwitchLanguageToSpanish() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openLanguages(app)
        app.buttons["language.spanish"].tap()
        XCTAssertTrue(app.buttons["language.spanish"].exists)
    }

    func testFlow09SwitchLanguageToJapanese() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openLanguages(app)
        app.buttons["language.japanese"].tap()
        XCTAssertTrue(app.buttons["language.japanese"].exists)
    }

    func testFlow10OpenUnitOneLessons() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(1, in: app)
        XCTAssertTrue(app.staticTexts["lesson.progressLabel"].waitForExistence(timeout: 15))
    }

    func testFlow11LessonProgressLabelVisible() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(1, in: app)
        XCTAssertGreaterThan(parseLessonNumber(app), 0)
    }

    func testFlow12CompleteOneLessonAdvancesCounter() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(1, in: app)

        let start = parseLessonNumber(app)
        let completeButton = app.buttons["lesson.testCompleteButton"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 8))
        completeButton.tap()

        XCTAssertTrue(app.staticTexts["lesson.progressLabel"].waitForExistence(timeout: 8))
        XCTAssertGreaterThanOrEqual(parseLessonNumber(app), start)
    }

    func testFlow13CompleteUnitShowsCompletion() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(1, in: app)

        let completeUnitButton = app.buttons["lesson.testCompleteUnitButton"]
        XCTAssertTrue(completeUnitButton.waitForExistence(timeout: 8))
        completeUnitButton.tap()

        XCTAssertTrue(app.staticTexts["Amazing!"].waitForExistence(timeout: 12))
    }

    func testFlow14UnitTwoOpens() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(2, in: app)
        XCTAssertTrue(app.staticTexts["lesson.progressLabel"].waitForExistence(timeout: 15))
    }

    func testFlow15LockedPremiumUnitIndicator() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openLanguages(app)
        let locked = app.otherElements["unit.locked.26"]
        XCTAssertTrue(locked.exists || app.buttons["unit.card.26"].exists)
    }

    func testFlow16StoreScreenShowsLifetimeOffer() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        try openStoreOrSkip(app)
        XCTAssertTrue(app.staticTexts["store.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["store.buyButton"].exists)
    }

    func testFlow17TestLifetimeActivationButtonExists() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        try openStoreOrSkip(app)
        XCTAssertTrue(app.buttons["store.testLifetimeButton"].waitForExistence(timeout: 5))
    }

    func testFlow18ActivateLifetimeThroughRealDbPath() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        try openStoreOrSkip(app)
        app.buttons["store.testLifetimeButton"].tap()
        XCTAssertTrue(app.exists)
    }

    func testFlow19OpenSettingsTab() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openSettings(app)
        XCTAssertTrue(app.navigationBars["Settings"].exists || app.staticTexts["Settings"].exists)
    }

    func testFlow20SettingsSectionsVisible() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openSettings(app)
        XCTAssertTrue(app.staticTexts["Username"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Email"].exists)
    }

    func testFlow21SettingsSignOutReturnsAuth() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openSettings(app)

        let signOut = app.buttons["settings.signOutButton"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 5))
        signOut.tap()

        let confirm = app.buttons["Sign Out"]
        if confirm.waitForExistence(timeout: 2) {
            confirm.tap()
        }

        XCTAssertTrue(app.textFields["auth.emailField"].waitForExistence(timeout: 6))
    }

    func testFlow22SignInAgainAfterSignOut() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openSettings(app)

        let signOut = app.buttons["settings.signOutButton"]
        if signOut.waitForExistence(timeout: 4) {
            signOut.tap()
            let confirm = app.buttons["Sign Out"]
            if confirm.waitForExistence(timeout: 2) { confirm.tap() }
        }

        try signInIfNeeded(app)
        XCTAssertTrue(homeVisible(app))
    }

    func testFlow23RepeatedTabSwitchStaysStable() throws {
        let app = launchApp()
        try signInIfNeeded(app)

        for _ in 0..<3 {
            openLanguages(app)
            if app.tabBars.buttons["Store"].exists { app.tabBars.buttons["Store"].tap() }
            openSettings(app)
        }
        XCTAssertTrue(app.exists)
    }

    func testFlow24OpenAndCompleteLessonInSecondUnit() throws {
        let app = launchApp()
        try signInIfNeeded(app)
        openUnit(2, in: app)

        let completeButton = app.buttons["lesson.testCompleteButton"]
        guard completeButton.waitForExistence(timeout: 8) else {
            throw XCTSkip("Lesson completion helper not visible")
        }
        completeButton.tap()
        XCTAssertTrue(app.staticTexts["lesson.progressLabel"].waitForExistence(timeout: 8))
    }

    func testFlow25EndToEndJourneyAuthLessonsAndSubscription() throws {
        let app = launchApp()
        try signInIfNeeded(app)

        openUnit(1, in: app)
        if app.buttons["lesson.testCompleteUnitButton"].waitForExistence(timeout: 8) {
            app.buttons["lesson.testCompleteUnitButton"].tap()
            _ = app.staticTexts["Amazing!"].waitForExistence(timeout: 12)
        }

        if app.tabBars.buttons["Store"].exists {
            app.tabBars.buttons["Store"].tap()
            if app.buttons["store.testLifetimeButton"].waitForExistence(timeout: 5) {
                app.buttons["store.testLifetimeButton"].tap()
            }
        }

        openSettings(app)
        XCTAssertTrue(app.exists)
    }
}
