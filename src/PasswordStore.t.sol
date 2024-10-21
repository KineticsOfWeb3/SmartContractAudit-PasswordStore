// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;
    DeployPasswordStore public deployer;
    address public owner;

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = address(this); // Set the owner to the contract deploying address
    }

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
    }

    function test_non_owner_reading_password_reverts() public {
        vm.startPrank(address(1));
        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
    }

    function test_non_owner_can_set_password_reverts() public {
        vm.startPrank(address(2));
        string memory newPassword = "hackedPassword"; // Password that a non-owner will try to set

        vm.expectRevert(PasswordStore.PasswordStore__NotAuthorized.selector);
        passwordStore.setPassword(newPassword);
    }

    // Additional test to show vulnerability in original contract (remove access control)
    function test_anyone_can_set_password_without_access_control() public {
        // Deploy the original contract without the access control
        PasswordStore vulnerablePasswordStore = new PasswordStore();

        // Attempt to set a password from a non-owner address
        vm.startPrank(address(3));
        string memory newPassword = "maliciousPassword"; // New password to set
        vulnerablePasswordStore.setPassword(newPassword); // Should succeed in the original contract

        // Verify the password has been set
        string memory actualPassword = vulnerablePasswordStore.getPassword();
        assertEq(actualPassword, newPassword); // The password should be what the non-owner set
    }
}
