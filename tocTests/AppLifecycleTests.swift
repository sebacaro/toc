import Testing
@testable import toc

@Suite("App lifecycle")
struct AppLifecycleTests {
    @Test("Test hosts do not start desktop services")
    func detectsXcodeTestEnvironment() {
        #expect(AppRuntime.isRunningTests(environment: ["XCTestConfigurationFilePath": "/tmp/tests.xctestconfiguration"]))
        #expect(AppRuntime.isRunningTests(environment: ["XCTestBundlePath": "/tmp/tocTests.xctest"]))
        #expect(AppRuntime.isRunningTests(environment: ["XCTestSessionIdentifier": "test-session"]))
    }

    @Test("Normal launches still start desktop services")
    func doesNotTreatOrdinaryEnvironmentAsTestHost() {
        #expect(!AppRuntime.isRunningTests(environment: [:]))
        #expect(!AppRuntime.isRunningTests(environment: ["PATH": "/usr/bin", "HOME": "/Users/example"]))
    }
}
