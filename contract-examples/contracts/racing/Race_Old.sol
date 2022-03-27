import "./AdminRoles.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract Race is AdminRoles {
    struct race {
        mapping(uint256 => uint256) birds;
        uint256 totalBirds;
        uint256 winner;
        uint256 start;
        uint256 fee;
        uint256 trackID;
    }
    struct track {
        uint256 elevationGain;
        uint256 length;
        uint256 linearity;
        uint256 condition;
        uint256 weather;
    }
    event raceCompleted(
        uint256 winner,
        address birdOwner,
        uint256 trackID,
        uint256 raceID
    );
    event raceInitialized(
        uint256 start,
        uint256 fee,
        uint256 track,
        uint256 id
    );
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
    // mapping(uint256 => track) public tracks;
    //uint256 public totalTacks;
    track[] public tracks;
    mapping(uint256 => race) public races;
    mapping(uint256 => bool) public raceLock;
    uint256 public totalRaces;
    address payable wallet;
    IERC721 Bird;

    constructor(address b) {
        Bird = IERC721(b);
    }

    function scheduleRace(
        uint256 start,
        uint256 fee,
        uint256 track
    ) public onlyAdmin {
        require(start > block.timestamp, "invalid start time");
        race storage r = races[totalRaces];
        r.start = start;
        r.fee = fee;
        r.trackID = track;
        totalRaces++;
    }

    function buildTrack(
        uint256 elevationGain,
        uint256 length,
        uint256 linearity,
        uint256 condition,
        uint256 weather
    ) public onlyAdmin {
        track memory t = track(
            elevationGain,
            length,
            linearity,
            condition,
            weather
        );
        tracks.push(t);
    }

    function deleteTrack(uint256 index) public onlyAdmin {}

    function getTrait(uint256 egg, traits t) public view returns (uint256) {
        uint256 index = uint256(uint8(t));
        if (index > 0) {
            return getDigitsSlice(egg, indices[index - 1], indices[index]);
        } else {
            return getDigitsSlice(egg, 0, indices[0]);
        }
    }

    function getTrackInfluence(
        uint256 value,
        uint256 trait,
        uint256 track
    ) public view returns (uint256) {
        if (trait == 0) {
            (uint256 d, bool pos) = getDifference(
                trait,
                tracks[track].elevationGain
            );
            return calcDiffScore(d, 10**4);
        }
        if (trait == 1) {
            (uint256 d, bool pos) = getDifference(trait, tracks[track].length);
            return calcDiffScore(d, 10**4);
        }
        if (trait == 2) {
            (uint256 d, bool pos) = getDifference(
                trait,
                tracks[track].linearity
            );
            return calcDiffScore(d, 10**4);
        }
        if (trait == 3) {
            (uint256 d, bool pos) = getDifference(
                trait,
                tracks[track].condition
            );
            return calcDiffScore(d, 10**4);
        }
        if (trait == 4) {} else {
            (uint256 d, bool pos) = getDifference(trait, tracks[track].weather);
            return calcDiffScore(d, 10**4);
        }
        return 0;
    }

    function calcDiffScore(uint256 d, uint256 m) public pure returns (uint256) {
        return m / (d + 1);
    }

    function getDifference(uint256 a, uint256 b)
        public
        pure
        returns (uint256 d, bool pos)
    {
        if (a >= b) {
            d = a - b;
            pos = true;
        } else {
            d = b - a;
            pos = false;
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

    function registerForRace(uint256 b, uint256 r) public payable {
        require(races[r].start > 0, "race has not been created");
        require(races[r].start > block.timestamp, "race has  not started");
        require(races[r].totalBirds < 10, "race has been filled");
        require(Bird.ownerOf(b) == msg.sender, "Bird must owned by sender");
        require(raceLock[b] == false, "race lock must be false");
        raceLock[b] = true;
        race storage r = races[r];
        r.birds[r.totalBirds] = b;
        r.totalBirds += 1;
        console.log(r.totalBirds, "total birds");
        if (r.fee > 0) {
            require(msg.value > r.fee, "invalid fee amount");
            //wallet.transfer(r.fee);
            payable(msg.sender).transfer(msg.value - r.fee);
        }
    }

    function getRaceScore(uint256 b, uint256 track)
        internal
        view
        returns (uint256)
    {
        uint256 temp;
        uint256 score;
        for (uint256 i = 0; i < 5; i++) {
            //temp = getDigitsSlice(b, indices[i - 1], indices[i]);
            temp = getProperty(b, i);
            temp += getTrackInfluence(temp, i, track);
            score += temp;
        }

        return score;
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

    function completeRace(uint256 id) public {
        require(block.timestamp > races[id].start, "race has not started");
        race storage r = races[id];
        uint256 highScore;
        uint256 winner;
        for (uint256 i = 0; i < r.totalBirds; i++) {
            console.log(r.birds[i]);
            uint256 temp = getRaceScore(r.birds[i], r.trackID);
            console.log(temp);
            highScore = temp > highScore ? temp : highScore;
            winner = r.birds[i];
        }
        r.winner = winner;
        console.log(winner, "THE WINNER!!");
        address owner = Bird.ownerOf(winner);
        payable(owner).transfer(r.fee * r.totalBirds);
        emit raceCompleted(winner, owner, r.trackID, id);
    }
}