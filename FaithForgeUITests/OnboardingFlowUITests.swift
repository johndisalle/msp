// OnboardingFlowUITests.swift
// FaithForgeUITests
//
// UI tests for the onboarding flow: welcome, sign-in, assessment, goal, completion.

import XCTest

final class OnboardingFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Welcome Screen

    func testWelcomeScreenShowsAppName() {
        // After launch screen animation (2 seconds), onboarding should appear
        let faithForgeTitle = app.staticTexts["FaithForge"]
        XCTAssertTrue(faithForgeTitle.waitForExistence(timeout: 5),
                      "FaithForge title should appear on welcome screen")
    }

    func testWelcomeScreenShowsTagline() {
        let tagline = app.staticTexts["Duolingo for Discipleship"]
        XCTAssertTrue(tagline.waitForExistence(timeout: 5),
                      "Tagline should appear on welcome screen")
    }

    func testWelcomeScreenHasGetStartedButton() {
        let button = app.buttons["Get Started"]
        XCTAssertTrue(button.waitForExistence(timeout: 5),
                      "Get Started button should exist on welcome screen")
    }

    // MARK: - Sign In Screen

    func testNavigateToSignInScreen() {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        // Should see sign-in options
        let continueAsGuest = app.buttons["Continue without Account"]
        XCTAssertTrue(continueAsGuest.waitForExistence(timeout: 3),
                      "Continue as Guest option should exist on sign-in screen")
    }

    func testContinueAsGuestMovesToAssessment() {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let guest = app.buttons["Continue without Account"]
        XCTAssertTrue(guest.waitForExistence(timeout: 3))
        guest.tap()

        // Should show faith assessment
        let assessmentHeader = app.staticTexts["Faith Assessment"]
        XCTAssertTrue(assessmentHeader.waitForExistence(timeout: 3),
                      "Faith Assessment screen should appear after guest sign-in")
    }

    // MARK: - Assessment Screen

    func testAssessmentShowsCategoryRatings() {
        navigateToAssessment()

        // Should show faith categories to rate
        let theWord = app.staticTexts["The Word"]
        XCTAssertTrue(theWord.waitForExistence(timeout: 3),
                      "Assessment should show The Word category")
    }

    func testAssessmentHasNextButton() {
        navigateToAssessment()

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 3),
                      "Assessment should have a Next button")
    }

    // MARK: - Daily Goal Screen

    func testDailyGoalScreenShowsIntensityOptions() {
        navigateToGoalPicker()

        let light = app.staticTexts["Light"]
        let moderate = app.staticTexts["Moderate"]
        let devoted = app.staticTexts["Devoted"]

        // At least one intensity option should be visible
        let anyVisible = light.exists || moderate.exists || devoted.exists
        XCTAssertTrue(anyVisible,
                      "Daily goal screen should show intensity options")
    }

    // MARK: - Full Flow

    func testCompleteOnboardingFlowReachesHome() {
        // Welcome → Get Started
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        // Sign In → Guest
        let guest = app.buttons["Continue without Account"]
        XCTAssertTrue(guest.waitForExistence(timeout: 3))
        guest.tap()

        // Assessment → Next (default ratings are fine)
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        next.tap()

        // Goal → Next / Continue
        let goalNext = app.buttons["Next"]
        if goalNext.waitForExistence(timeout: 3) {
            goalNext.tap()
        }

        // Completion → Let's Begin / Start
        let begin = app.buttons["Let's Begin"]
        if begin.waitForExistence(timeout: 3) {
            begin.tap()
        } else {
            // Try alternate button text
            let start = app.buttons["Start Your Journey"]
            if start.waitForExistence(timeout: 2) {
                start.tap()
            }
        }

        // Should now see the main tab bar with Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5),
                      "Home tab should be visible after completing onboarding")
    }

    // MARK: - Helpers

    private func navigateToAssessment() {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let guest = app.buttons["Continue without Account"]
        XCTAssertTrue(guest.waitForExistence(timeout: 3))
        guest.tap()
    }

    private func navigateToGoalPicker() {
        navigateToAssessment()

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        next.tap()
    }
}
