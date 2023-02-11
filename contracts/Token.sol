//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract Token is ERC1155URIStorage {
    constructor() ERC1155("") {}

    function getAdTokens(address account, uint256 amount) external {
        _mint(account, 0, amount, "");
    }
}
