pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AdminRoles.sol";
import "hardhat/console.sol";

interface Mintable is IERC721 {
    function mint(address to, uint256 id) external;
}

contract hatchery {
    //Stamina,Cunning Endurance,Acceleration,Max Speed, Luck, Sex, Bloodline,Beak,Body,Feather,Wing,Personality,Breed All start from 0
    //0,        1,      2,          3,        4,          5,    6,    7,      8,      9,  10,  11,     12   13  14
    uint256[] private maxValues = [
        99, //Stamina
        99, // Cunning
        99, // Endurance
        99, // Acceleration
        99, // Max Spped
        99, //luck
        1, //Sex
        3, //Bloodline
        2, //Beak
        3, //Body
        6, //Feather
        2, //Wing
        50, //Personality
        5 //Breed
    ];
    uint256[] private decimals = [2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 1];
    uint256[] private indices = [
        2,
        4,
        6,
        8,
        10,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        20,
        21
    ];
    uint256[][] breedDominances = [
        [100, 75, 60, 0, 0, 0],
        [0, 100, 75, 60, 0, 0],
        [0, 0, 100, 75, 60, 0],
        [0, 0, 0, 100, 75, 60],
        [60, 0, 0, 0, 100, 75],
        [75, 60, 0, 0, 0, 100]
    ];
    uint256[][] bloodDominances = [
        [0, 0, 100, 90],
        [90, 0, 0, 100],
        [100, 90, 0, 0],
        [0, 100, 90, 0]
    ];

    enum traits {
        STAMINA,
        CUNNING,
        ENDURANCE,
        ACCELERATION,
        SPEEDMAX,
        LUCK,
        SEX,
        BLOODLINE,
        BEAK,
        BODY,
        FEATHER,
        WING,
        PERSONALITY,
        BREED
    }
    //true:male false:female

    mapping(bool => uint256) breedLimits;
    mapping(uint256 => uint256) totalBreeding;

    mapping(uint256 => uint256) breedingMonthlyCount;
    mapping(uint256 => uint256) breedingYearCount;
    Mintable public Egg;
    uint256 weightDecimals = 1000;

    constructor(address token) {
        Egg = Mintable(token);
    }

    function generateRandomDNA(uint256 randomSeed)
        public
        view
        returns (uint256 Genetics)
    {
        uint256 _start = 0;
        uint256 _x = randomSeed % 1000000;
        for (uint256 i = 0; i < decimals.length; i++) {
            _x = uint256(keccak256(abi.encodePacked(_x)));
            if (i == decimals.length - 1) {
                //last property must have a minimum of 1
                Genetics +=
                    createRandomInInterval(1, maxValues[i], _x) *
                    10**_start;
            } else {
                Genetics +=
                    createRandomInInterval(0, maxValues[i], _x) *
                    10**_start;
            }

            _start += decimals[i];
        }
    }

    function mintRandom(uint256 randomSeed, address recipient) public {
        uint256 DNA = generateRandomDNA(randomSeed);
        Egg.mint(recipient, DNA);
    }

    function validToBreed(
        uint256 t1,
        uint256 t2,
        bool s1,
        bool s2
    ) internal returns (bool) {
        return
            (totalBreeding[t1] < breedLimits[s1]) &&
            (totalBreeding[t2] < breedLimits[s2]);
    }

    function getMockRandom(uint256 i) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(i, block.timestamp, block.difficulty)
                )
            );
    }

    function mockBreeder(uint256 b1, uint256 b2) public {
        uint256 sex1 = getProperty(b1, 7);
        uint256 sex2 = getProperty(b2, 7);

        uint256 newDNA = 0;
        uint256 _start = 0;
        //console.log(sex1, "sex1");
        //console.log(sex2, "sex2");
        require(
            (Egg.ownerOf(b1) == msg.sender) && (Egg.ownerOf(b1) == msg.sender),
            "msg.sender must own both nfts"
        );
        require(sex1 != sex2, "cannot breed two birds of the same sex");
        for (uint256 i = 0; i < maxValues.length; i++) {
            newDNA += (10**_start) * averageTraits(b1, b2, i, 0);

            _start += decimals[i];
        }
        totalBreeding[b1] += 1;
        totalBreeding[b2] += 1;
        Egg.mint(msg.sender, newDNA);
    }

    function mockBreederCallback(
        uint256 b1,
        uint256 b2,
        uint256 vrf
    ) internal {
        uint256 sex1 = getProperty(b1, 7);
        uint256 sex2 = getProperty(b2, 7);

        uint256 newDNA = 0;
        uint256 _start = 0;
        //console.log(sex1, "sex1");
        //console.log(sex2, "sex2");
        require(
            (Egg.ownerOf(b1) == msg.sender) && (Egg.ownerOf(b1) == msg.sender),
            "msg.sender must own both nfts"
        );
        require(sex1 != sex2, "cannot breed two birds of the same sex");
        for (uint256 i = 0; i < maxValues.length; i++) {
            newDNA += (10**_start) * averageTraits(b1, b2, i, 0);

            _start += decimals[i];
        }
        totalBreeding[b1] += 1;
        totalBreeding[b2] += 1;
        Egg.mint(msg.sender, newDNA);
    }

    function getTraitSplit(
        uint256 index,
        uint256 b1,
        uint256 b2
    ) internal view returns (uint256 split1, uint256 split2) {
        uint256 bloodline1 = getTrait(b1, traits.BLOODLINE);
        uint256 bloodline2 = getTrait(b2, traits.BLOODLINE);

        if (
            breedDominances[bloodline1][index] ==
            breedDominances[bloodline2][index]
        ) {
            split1 = 500;
            split2 = 500;
        } else {
            split1 = breedDominances[bloodline1][index] >
                breedDominances[bloodline2][index]
                ? breedDominances[bloodline1][index] * 10
                : breedDominances[bloodline2][index] * 10;
            split2 = 1000 - split1;
        }
    }

    function getBreedSplit(
        uint256 index,
        uint256 b1,
        uint256 b2
    ) internal view returns (uint256 split1, uint256 split2) {
        split1 = 500;
        split2 = 500;
    }

    function createRandomInInterval(
        uint256 min,
        uint256 max,
        uint256 _rv
    ) public pure returns (uint256) {
        if (max == min) {
            return max;
        } else {
            uint256 diff = max - min;

            if (diff == 1) diff = 2;
            uint256 result = (_rv % diff);
            return (result + min);
        }
    }

    function getDigitsSlice(
        uint256 number,
        uint256 start,
        uint256 end
    ) public pure returns (uint256) {
        require((number >= 10**start), "number must be larger than start");
        require(end > start, "must be a valid start and end");
        return (number / 10**start) % 10**(end - start);
    }

    function returnTraitsAsArray(uint256 dna)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory traits = new uint256[](14);

        for (uint256 i = 0; i < decimals.length; i++) {
            //console.log(i);

            traits[i] = (getProperty(dna, i));
            //console.log(dna);
            //console.log(traits[i]);
        }
        return traits;
    }

    function averageTraits(
        uint256 b1,
        uint256 b2,
        uint256 index,
        uint256 r
    ) public view returns (uint256) {
        uint256 v1 = getProperty(b1, index);
        uint256 v2 = getProperty(b2, index);
        uint256 split1;
        uint256 split2;
        if (index < 6) {
            (split1, split2) = getTraitSplit(index, b1, b2);
        } else {
            if (index == 6) {
                return getMockRandom(r) % 2;
            }
            if (index == 7) {
                return getMockRandom(r) % maxValues[7];
            }
            if (index >= 8 && index <= 12) {
                (split1, split2) = getBreedSplit(index, b1, b2);
            }
            if (index == 13) {
                return getMockRandom(r) % maxValues[13];
            }
        }
        console.log(index, "index");
        console.log(v1, "value 1");
        console.log(v2, "value 2");
        console.log(
            ((v1 * split1 + v2 * split2) / weightDecimals + r) %
                maxValues[index]
        );
        return
            ((v1 * split1 + v2 * split2) / weightDecimals + r) %
            maxValues[index];
    }

    /**
     */
    function probabilityHandler(uint256[] memory intervals, uint256 rv)
        public
        view
        returns (uint256 ret)
    {
        for (uint256 i = 0; i < intervals.length; i++) {
            if (i == 0) {
                if (rv < intervals[0]) {
                    ret = 1;
                }
            } else {
                if (
                    (i > intervals[i - 1] && i < intervals[i]) ||
                    (i > intervals[i] && i == intervals.length - 1)
                ) {
                    ret = i + 1;
                }
            }
        }
    }

    function getProperty(uint256 egg, uint256 index)
        public
        view
        returns (uint256)
    {
        if (index > 0) {
            return getDigitsSlice(egg, indices[index - 1], indices[index]);
        } else {
            return getDigitsSlice(egg, 0, indices[0]);
        }
    }

    function getTrait(uint256 egg, traits t) public view returns (uint256) {
        uint256 index = uint256(uint8(t));
        return getProperty(egg, index);
    }
}