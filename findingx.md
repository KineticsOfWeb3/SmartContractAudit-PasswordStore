### [H-1] Exposure of Sensitive Data: On-Chain Passwords Are Public Despite Visibility Restrictions

**Description:**
All data stored on-chain is publicly accessible and can be read directly from the blockchain, regardless of Solidity’s visibility modifiers. In the `PasswordStore` contract, the `s_password` variable is intended to be a private variable, accessible only through the `getPassword` function, which is restricted to the contract owner. However, since Solidity stores all variables on-chain, this "private" password can still be read by anyone through blockchain explorers or by directly querying the storage, making the password publicly visible and defeating the intended privacy.

**Impact:**
Anyone can directly access and read the so-called "private" password stored on-chain, severely compromising the security and intended functionality of the protocol. This exposure renders the protocol vulnerable, as malicious actors can retrieve sensitive information, leading to potential unauthorized actions, trust breaches, and loss of data confidentiality.

### **Proof of Concept:** Proof of Code

Below is a test case that demonstrates how anyone can read the "private" password directly from the blockchain.

1. **Start a Local Blockchain:**

   Run a local chain using Anvil:

   ```bash
   make anvil
   ```

2. **Deploy the Contract:**

   Deploy the `PasswordStore` contract onto the locally running chain:

   ```bash
   make deploy
   ```

3. **Inspect Contract Storage:**

   Use the `cast` tool to inspect the storage of the deployed contract:

   ```bash
   cast storage 0x5fbdb2315678afecb367f032d93f642f64180aa3 --rpc-url http://127.0.0.1:8545/
   ```

   This will output the storage slots and their values, allowing you to view all the variables stored in the contract.

4. **Retrieve the Password from Storage:**

   To specifically retrieve the password stored in slot `1`, use the following command:

   ```bash
   cast storage 0x5fbdb2315678afecb367f032d93f642f64180aa3 1 --rpc-url http://127.0.0.1:8545/
   ```

   You should see an output like this, which is the byte representation of the password:

   ```bash
   0x6d7950617373776f726400000000000000000000000000000000000000000014
   ```

5. **Decode the Password:**

   Convert the `bytes32` string back to its human-readable form:

   ```bash
   cast --parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
   ```

   The output will be the original password:

   ```bash
   myPassword
   ```

Here’s a refined version of your **Recommended Mitigation**:

---

### **Recommended Mitigation:**

To address this issue, the overall architecture of the contract should be reconsidered. Instead of storing sensitive information like passwords directly on-chain, it is recommended to **encrypt the password off-chain** before storing it on-chain. This approach ensures that only the encrypted version of the password is visible on-chain.

To implement this:

1. **Encrypt the password off-chain**: Before sending the password to the contract, the user should encrypt it off-chain using a secure encryption method.
2. **Store the encrypted password on-chain**: The contract will only store the encrypted password, ensuring that the actual password remains confidential.

3. **Off-chain decryption**: The user will need to securely store the key or password required to decrypt the encrypted password off-chain. This adds a layer of security as the decryption process will not involve the blockchain, preventing exposure.

4. **Remove the view function**: Consider removing the `view` function used to retrieve the password, as this could lead to accidental exposure of the encrypted password. The user should avoid accidentally sending sensitive data via transactions that could decrypt their password.

### [H-2] Lack of Access Control in `PasswordStore::setPassword` Allows Unauthorized Password Changes

**Description:** The `PasswordStore::setPassword` function is marked as external, but its intended purpose is to allow only the contract owner to set a new password. However, due to the lack of access control, anyone can call this function, which contradicts the intended behavior of restricting password changes to the owner.

```Javascript
   // @audit missing acess control, any user can set a password
    function setPassword(string memory newPassword) external {
        s_password = newPassword;
        emit SetNetPassword();
    }
```

**Impact:** Unauthorized users can set or modify the contract's password, undermining its security and breaking the intended functionality, as control over the password is no longer restricted to the owner.

**Proof of Concept:** Add the following to `PasswordStore.t.sol` test files.

<details>
<summary>CODE</summary>

```javascript

function test_non_owner_reading_password_reverts() public {
vm.startPrank(address(1));
vm.expectRevert(PasswordStore.PasswordStore\_\_NotOwner.selector);
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
```

</details>

**Recommended Mitigation:** Add an acess control conditional to the `setPassword` function.

if(msg.sender != s_owner){
revert PasswordStore\_\_NotOwner();
}

### [L-3] Incorrect Natspec Parameter in PasswordStore::setPassword Leading to Potential Usage Errors

**Description:**
The `PasswordStore::setPassword` function's Natspec documentation inaccurately references a parameter called newPassword that does not exist in the function's signature. This discrepancy creates confusion about the expected inputs for the function.

**Impact:**
This inconsistency in the Natspec documentation can mislead developers and auditors, leading to incorrect usage of the function. Users might expect the function to accept a non-existent parameter, potentially resulting in security vulnerabilities or functional errors in the contract.

**Proof of Concept:**
_To illustrate the issue, consider the following scenario:_

A developer attempts to call the `setPassword` function based on the current Natspec documentation, expecting to pass a parameter named newPassword.
Since `newPassword` is referenced in the documentation but not defined in the function's signature, the developer may be confused or make incorrect assumptions about the function's behavior.
This can lead to unintended consequences, such as failing to pass the intended password or misusing the function entirely.

**Recommended Mitigation:**
Update the Natspec for the `setPassword` function to accurately describe the parameter according to its signature. Ensure all documentation across the contract is consistent and reflective of the actual implementation. This can be done by modifying the Natspec comment as follows:

```javascript

/*
 * @notice This function allows only the owner to set a new password.
 * @param newPassword The new password to set.
 */
function setPassword(string memory newPassword) external {
    s_password = newPassword;
    emit SetNetPassword();
}
```

```diff
-  @param newPassword The new password to set
```
