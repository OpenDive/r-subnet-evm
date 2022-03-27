package precompile

import (
	
	"fmt"
	"math/big"
	
	"github.com/ethereum/go-ethereum/common"
)

// Enum constants for valid AllowListRole
const (
    nft_delim = byte('/')
)

var (
    _ StatefulPrecompileConfig = (*RaceCalculatorConfig)(nil)

  
    RaceCalculatorPrecompile StatefulPrecompiledContract = createRandomPartyPrecompile(RaceCalculatorAddress)
)

var (
	
	// AllowList function signatures
	raceScoreSignature  = CalculateFunctionSelector("getRaceScore(uint256[] memory birds, uint256[] memory track)")
	

	// Error returned when an invalid write is attempted
	
	scoreInputLen = common.HashLength + common.HashLength
)
type RaceCalculatorConfig struct {
    BlockTimestamp *big.Int `json:"blockTimestamp"`

    PhaseSeconds *big.Int `json:"phaseSeconds"`
    CommitStake  *big.Int `json:"commitStake"`
}

// Address returns the address of the RaceCalculator contract.
func (c *RaceCalculatorConfig) Address() common.Address {
    return RaceCalculatorAddress
}

// Timestamp returns the timestamp at which the Random Party should be enabled
func (c *RaceCalculatorConfig) Timestamp() *big.Int { return c.BlockTimestamp }


func (c *RaceCalculatorConfig) Configure(state StateDB) {
    SetPhaseSeconds(state, c.PhaseSeconds)
    SetCommitStake(state, c.CommitStake)
}

// Contract returns the singleton stateful precompiled contract to be used for
// the Random Party.
func (c *RaceCalculatorConfig) Contract() StatefulPrecompiledContract {
    return RaceCalculatorPrecompile
}



// UnPackScoreInput attempts to unpack [input] into the arguments to the mint precompile
// assumes that [input] does not include selector (omits first 4 bytes in PackScoreInput)
func UnPackScoreInput(input []byte) ([]*big.Int, []*big.Int, error) {
	var (
        birdLen = new(big.Int).SetBytes(input[0:32])
    )

    var birdArr []*big.Int 
    
    
    end := 0
    for idx := int64(0); idx < birdLen.Int64(); idx++ {
        start := 32 * (idx + 1)
        _end := start + 32
        bird := new(big.Int).SetBytes(input[start: _end])

        fmt.Println("BIRD %d: %d", idx, bird)
        birdArr[idx] = bird
		end+=32
    }

    var (
        trackLen = new(big.Int).SetBytes(input[end: end + 32])
		
    )

	end+=32
    var trackArr []*big.Int 
    for idx := int64(0); idx < trackLen.Int64(); idx++ {
        track:= new(big.Int).SetBytes(input[end: end+32])
		end+=32
		trackArr[idx]=track
        fmt.Println("BIRD %d: %d", idx, track)
    }
 
 
	return birdArr, trackArr, nil
}
func packOutputAsBytes(score *big.Int,winnerIndex *big.Int)  ([]byte, error){
	
	input := make([]byte, 64)
	score.FillBytes(input[0 :32])
	winnerIndex.FillBytes(input[32:64])
	return input, nil
	
}
func calculateTraitValues(b *big.Int ) ([14]*big.Int) {
	indices := [14]int64{
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
		21}
	var values [14]*big.Int 
	for i := 0; i < 14; i++ {
	 if i==0 {
		values[i]=digitSlice(b,big.NewInt(0),big.NewInt(indices[0]))	
	 }else{
		values[i]=digitSlice(b,big.NewInt(indices[i-1]),big.NewInt(indices[i]))	
	 }
	
	}
	return values
}        
func getHighestScore(evm PrecompileAccessibleState, callerAddr, addr common.Address, input []byte, suppliedGas uint64, value *big.Int, readOnly bool) (ret []byte, remainingGas uint64, err error) {

	birds,track,nil :=UnPackScoreInput(input)
	score,winnerIndex :=_getHighestScore( birds, track)
	output,nil:= packOutputAsBytes(score,winnerIndex)
	return output, remainingGas, nil
}
func _getHighestScore( birds []*big.Int, track []*big.Int) ( *big.Int,*big.Int,){
	highScore := big.NewInt(0)
	winnerIndex:=0
	for i := 0; i < len(birds); i++ {
		traits:= calculateTraitValues(birds[i]) 
		score:=getRaceScore(traits, track)
		if highScore.Cmp(score)==-1{
			highScore=score
			winnerIndex=i
		}

	}
	
	return highScore ,big.NewInt(int64(winnerIndex))
}
func getRaceScore(bird [14]*big.Int, track []*big.Int)  *big.Int{
	score :=big.NewInt(0)
	
	score =score.Add(score,diffScore(bird[0],track[0]))
	score =score.Add(score,diffScore(bird[1],track[2]))
	score =score.Add(score,diffScore(bird[2],track[1]))
	score =score.Add(score,diffScore(bird[3],track[3]))
	score =score.Add(score,diffScore(bird[4],Average(track)))
	score =score.Add(score,diffScore(bird[12],track[4]))
	return score

}
func Average(values []*big.Int ) *big.Int{
	start := big.NewInt(0)
	
	for i := 0; i < len(values); i++ {
		start.Add(start,values[i])
	}
	length:=big.NewInt(int64(len(values)))
	return start.Div(start,length)
}
func diffScore(a *big.Int,b *big.Int) *big.Int{
	diff:=a.Sub(a,b)
	diff=diff.Abs(diff)
	max:= big.NewInt(10000)
	return max.Div(max,diff)
}
func digitSlice(number *big.Int,
	start *big.Int,
	 end *big.Int)(*big.Int) {
		
	p1:= number.Div(number, big.NewInt(10).Exp(big.NewInt(10),start,nil))
	p2:=big.NewInt(10).Exp(big.NewInt(10), end.Sub(end,start),nil)
	return p1.Mod(p1,p2)

}
func createNativeScorePrecompile(precompileAddr common.Address) StatefulPrecompiledContract {
	 //setAdmin := newStatefulPrecompileFunction(setAdminSignature, createAllowListRoleSetter(precompileAddr, AllowListAdmin))
	 getHighestScore := newStatefulPrecompileFunction(raceScoreSignature , getHighestScore)
	// Construct the contract with no fallback function.
	contract := newStatefulPrecompileWithFunctionSelectors(nil, []*statefulPrecompileFunction{getHighestScore})
	return contract
}
