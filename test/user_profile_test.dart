/*
 * Unit tests for the API class
 */

import "package:test/test.dart";
import "package:inventree/user_profile.dart";

import "setup.dart";

void main() {
  setupTestEnv();

  setUp(() async {
    // Ensure we have a user profile available
    // This profile will match the dockerized InvenTree setup, running locally

    // To start with, there should not be *any* profiles available
    var profiles = await UserProfileDBManager().getAllProfiles();

    for (var prf in profiles) {
      await UserProfileDBManager().deleteProfile(prf);
    }

    // Check that there are *no* profiles in the database
    profiles = await UserProfileDBManager().getAllProfiles();
    expect(profiles.length, equals(0));

    // Now, create one!
    bool result = await UserProfileDBManager().addProfile(
      UserProfile(
        name: testServerName,
        server: testServerAddress,
        selected: true,
      ),
    );

    expect(result, equals(true));

    // Ensure we have one profile available
    // expect(profiles.length, equals(1));
    profiles = await UserProfileDBManager().getAllProfiles();

    expect(profiles.length, equals(1));

    int key = -1;

    // Find the first available profile
    for (var p in profiles) {
      if (p.key != null) {
        key = p.key ?? key;
        break;
      }
    }

    // Select the profile
    await UserProfileDBManager().selectProfile(key);
  });

  // Run a set of tests for user profile functionality
  group("Profile Tests:", () {
    test("Add Invalid Profiles", () async {
      // Add a profile with missing data
      bool result = await UserProfileDBManager().addProfile(UserProfile());

      expect(result, equals(false));

      // Add a profile with a new name
      result = await UserProfileDBManager().addProfile(
        UserProfile(name: "Another Test Profile"),
      );

      expect(result, equals(true));

      // Check that the number of protocols available is still the same
      var profiles = await UserProfileDBManager().getAllProfiles();

      expect(profiles.length, equals(2));
    });

    test("Profile Name Check", () async {
      bool result = await UserProfileDBManager().profileNameExists(
        "doesnotexist",
      );
      expect(result, equals(false));

      result = await UserProfileDBManager().profileNameExists("Test Server");
      expect(result, equals(true));
    });

    test("Select Profile", () async {
      // Ensure that we can select a user profile
      final prf = await UserProfileDBManager().getSelectedProfile();

      expect(prf, isNot(null));

      if (prf != null) {
        UserProfile p = prf;

        expect(p.name, equals(testServerName));
        expect(p.server, equals(testServerAddress));

        expect(
          p.toString(),
          equals("<${p.key}> Test Server : http://localhost:8000/"),
        );

        // Test that we can update the profile
        p.name = "different name";

        bool result = await UserProfileDBManager().updateProfile(p);
        expect(result, equals(true));
      }
    });
  });
}
