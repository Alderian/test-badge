// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ScrollBadgeAccessControl } from
    "@canva-contracts/badge/extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadgeDefaultURI } from "@canva-contracts/badge/extensions/ScrollBadgeDefaultURI.sol";
import { ScrollBadgeEligibilityCheck } from
    "@canva-contracts/badge/extensions/ScrollBadgeEligibilityCheck.sol";
import { ScrollBadgeNoExpiry } from "@canva-contracts/badge/extensions/ScrollBadgeNoExpiry.sol";
import { ScrollBadgeSingleton } from "@canva-contracts/badge/extensions/ScrollBadgeSingleton.sol";
import { ScrollBadge } from "@canva-contracts/badge/ScrollBadge.sol";
import { Unauthorized } from "@canva-contracts/Errors.sol";

import { IActivityPoints } from "../interfaces/IActivityPoints.sol";

/**
 * @title ScrollBadgeLevelsScrolly
 * @author Alderian
 * @notice A badge that represents the Scrolly user's level.
 */
contract ScrollBadgeLevelsScrolly is
    ScrollBadgeAccessControl,
    ScrollBadgeDefaultURI,
    ScrollBadgeEligibilityCheck,
    ScrollBadgeNoExpiry,
    ScrollBadgeSingleton
{
    uint256 public immutable MINIMUM_POINTS_ELIGIBILITY = 1 ether; // Scrolly Baby
    uint256 public immutable MINIMUM_POINTS_LEVEL_2 = 667 ether; // Scrolly Novice
    uint256 public immutable MINIMUM_POINTS_LEVEL_3 = 1221 ether; // Scrolly Explorer
    uint256 public immutable MINIMUM_POINTS_LEVEL_4 = 2442 ether; // Master Mapper
    uint256 public immutable MINIMUM_POINTS_LEVEL_5 = 4200 ether; // Carto Maestro
    uint256 public immutable MINIMUM_POINTS_LEVEL_6 = 6000 ether; // Grand Cartographer of Scrolly
    address public apAddress; // activity points contract address
    string public baseBadgeURI;

    error ZeroAddress();

    constructor(
        address resolver_,
        address activityPoints_,
        string memory _defaultBadgeURI, // IPFS, HTTP, or data URL
        string memory _baseBadgeURI // IPFS, HTTP, or data URL to add level to get image
    )
        ScrollBadge(resolver_)
        ScrollBadgeDefaultURI(_defaultBadgeURI)
    {
        if (activityPoints_ == address(0)) {
            revert ZeroAddress();
        }

        apAddress = activityPoints_;
        baseBadgeURI = _baseBadgeURI;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeNoExpiry, ScrollBadgeSingleton)
        returns (bool)
    {
        if (!isEligible(attestation.recipient)) {
            revert Unauthorized();
        }

        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeNoExpiry, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadgeDefaultURI
    function getBadgeTokenURI(bytes32 uid) internal view override returns (string memory) {
        // We get current user level from latest attestation (using provided badge logic)
        uint8 level = getCurrentLevel(uid);

        return string(abi.encodePacked(baseBadgeURI, Strings.toString(level), ".json"));
    }

    function getCurrentLevel(bytes32 uid) public view returns (uint8) {
        Attestation memory badge = getAndValidateBadge(uid);
        return getLevel(badge.recipient);
    }

    function isEligible(address recipient) public view override returns (bool) {
        return (IActivityPoints(apAddress).getPoints(recipient) >= MINIMUM_POINTS_ELIGIBILITY);
    }

    /**
     * @dev This makes it easier to get the badge url using user address
     */
    function getTokenURI(address recipient) external view returns (string memory) {
        // We get current user level from latest attestation (using provided badge logic)
        uint8 level = getLevel(recipient);

        return string(abi.encodePacked(baseBadgeURI, Strings.toString(level), ".json"));
    }

    function getPoints(address recipient) public view returns (uint256) {
        return IActivityPoints(apAddress).getPoints(recipient);
    }

    function getLevel(address recipient) public view returns (uint8) {
        return determineBadgeLevel(IActivityPoints(apAddress).getPoints(recipient));
    }

    function determineBadgeLevel(uint256 points) public pure returns (uint8) {
        if (points <= MINIMUM_POINTS_ELIGIBILITY) {
            return 0; // 0 - unrevealed - minimum not meet
        } else if (points < MINIMUM_POINTS_LEVEL_2) {
            return 1; // 1 - Scrolly Baby
        } else if (points < MINIMUM_POINTS_LEVEL_3) {
            return 2; // 2- Scrolly Novice
        } else if (points < MINIMUM_POINTS_LEVEL_4) {
            return 3; // 3 - Scrolly Explorer
        } else if (points < MINIMUM_POINTS_LEVEL_5) {
            return 4; // 4 - Master Mapper
        } else if (points < MINIMUM_POINTS_LEVEL_6) {
            return 5; // 5 - Carto Maestro
        } else {
            return 6; // 6 - Grand Cartographer of Scrolly
        }
    }

    function setDefaultBadgeURI(string memory _defaultBadgeURI) external onlyOwner {
        defaultBadgeURI = _defaultBadgeURI;
    }

    function setBaseBadgeURI(string memory _baseBadgeURI) external onlyOwner {
        baseBadgeURI = _baseBadgeURI;
    }

    function setApAddress(address _apAddress) external onlyOwner {
        if (_apAddress == address(0)) {
            revert ZeroAddress();
        }
        apAddress = _apAddress;
    }
}
