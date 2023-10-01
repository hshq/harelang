// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The test data below is based on Go's implementation, and came with the
// following note and copyright notice:
//
// The expected results below were computed by the high precision calculators
// at https://keisan.casio.com/.  More exact input values (array vf[], above)
// were obtained by printing them with "%.26f".  The answers were calculated
// to 26 digits (by using the "Digit number" drop-down control of each
// calculator).
//
// The Go copyright notice:
// ====================================================
// Copyright (c) 2009 The Go Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ====================================================

use math;

// The higher-precision values in VC26 were used to derive the
// input arguments VC. For reference only (do not delete).
const VC26: []c128 = [
	(4.97901192488367350108546816, 7.73887247457810456552351752),
	(7.73887247457810456552351752, -0.27688005719200159404635997),
	(-0.27688005719200159404635997, -5.01060361827107492160848778),
	(-5.01060361827107492160848778, 9.63629370719841737980004837),
	(9.63629370719841737980004837, 2.92637723924396464525443662),
	(2.92637723924396464525443662, 5.22908343145930665230025625),
	(5.22908343145930665230025625, 2.72793991043601025126008608),
	(2.72793991043601025126008608, 1.82530809168085506044576505),
	(1.82530809168085506044576505, -8.68592476857560136238589621),
	(-8.68592476857560136238589621, 4.97901192488367350108546816),
];

const VC: []c128 = [
	(4.9790119248836735e+00, 7.7388724745781045e+00),
	(7.7388724745781045e+00, -2.7688005719200159e-01),
	(-2.7688005719200159e-01, -5.0106036182710749e+00),
	(-5.0106036182710749e+00, 9.6362937071984173e+00),
	(9.6362937071984173e+00, 2.9263772392439646e+00),
	(2.9263772392439646e+00, 5.2290834314593066e+00),
	(5.2290834314593066e+00, 2.7279399104360102e+00),
	(2.7279399104360102e+00, 1.8253080916808550e+00),
	(1.8253080916808550e+00, -8.6859247685756013e+00),
	(-8.6859247685756013e+00, 4.9790119248836735e+00),
];

// The expected results below were computed by the high precision calculators
// at https://keisan.casio.com/.  More exact input values (array vc[], above)
// were obtained by printing them with "%.26f".  The answers were calculated
// to 26 digits (by using the "Digit number" drop-down control of each
// calculator).

const TEST_ABS: []f64 = [
	9.2022120669932650313380972e+00,
	7.7438239742296106616261394e+00,
	5.0182478202557746902556648e+00,
	1.0861137372799545160704002e+01,
	1.0070841084922199607011905e+01,
	5.9922447613166942183705192e+00,
	5.8978784056736762299945176e+00,
	3.2822866700678709020367184e+00,
	8.8756430028990417290744307e+00,
	1.0011785496777731986390856e+01,
];

const TEST_ACOS: []c128 = [
	(1.0017679804707456328694569, -2.9138232718554953784519807),
	(0.03606427612041407369636057, 2.7358584434576260925091256),
	(1.6249365462333796703711823, 2.3159537454335901187730929),
	(2.0485650849650740120660391, -3.0795576791204117911123886),
	(0.29621132089073067282488147, -3.0007392508200622519398814),
	(1.0664555914934156601503632, -2.4872865024796011364747111),
	(0.48681307452231387690013905, -2.463655912283054555225301),
	(0.6116977071277574248407752, -1.8734458851737055262693056),
	(1.3649311280370181331184214, 2.8793528632328795424123832),
	(2.6189310485682988308904501, -2.9956543302898767795858704),
];

const TEST_ACOSH: []c128 = [
	(2.9138232718554953784519807, 1.0017679804707456328694569),
	(2.7358584434576260925091256, -0.03606427612041407369636057),
	(2.3159537454335901187730929, -1.6249365462333796703711823),
	(3.0795576791204117911123886, 2.0485650849650740120660391),
	(3.0007392508200622519398814, 0.29621132089073067282488147),
	(2.4872865024796011364747111, 1.0664555914934156601503632),
	(2.463655912283054555225301, 0.48681307452231387690013905),
	(1.8734458851737055262693056, 0.6116977071277574248407752),
	(2.8793528632328795424123832, -1.3649311280370181331184214),
	(2.9956543302898767795858704, 2.6189310485682988308904501),
];

const TEST_ASIN: []c128 = [
	(0.56902834632415098636186476, 2.9138232718554953784519807),
	(1.5347320506744825455349611, -2.7358584434576260925091256),
	(-0.054140219438483051139860579, -2.3159537454335901187730929),
	(-0.47776875817017739283471738, 3.0795576791204117911123886),
	(1.2745850059041659464064402, 3.0007392508200622519398814),
	(0.50434073530148095908095852, 2.4872865024796011364747111),
	(1.0839832522725827423311826, 2.463655912283054555225301),
	(0.9590986196671391943905465, 1.8734458851737055262693056),
	(0.20586519875787848611290031, -2.8793528632328795424123832),
	(-1.0481347217734022116591284, 2.9956543302898767795858704),
];

const TEST_ASINH: []c128 = [
	(2.9113760469415295679342185, 0.99639459545704326759805893),
	(2.7441755423994259061579029, -0.035468308789000500601119392),
	(-2.2962136462520690506126678, -1.5144663565690151885726707),
	(-3.0771233459295725965402455, 1.0895577967194013849422294),
	(3.0048366100923647417557027, 0.29346979169819220036454168),
	(2.4800059370795363157364643, 1.0545868606049165710424232),
	(2.4718773838309585611141821, 0.47502344364250803363708842),
	(1.8910743588080159144378396, 0.56882925572563602341139174),
	(2.8735426423367341878069406, -1.362376149648891420997548),
	(-2.9981750586172477217567878, 0.5183571985225367505624207),
];

const TEST_ATAN: []c128 = [
	(1.5115747079332741358607654, 0.091324403603954494382276776),
	(1.4424504323482602560806727, -0.0045416132642803911503770933),
	(-1.5593488703630532674484026, -0.20163295409248362456446431),
	(-1.5280619472445889867794105, 0.081721556230672003746956324),
	(1.4759909163240799678221039, 0.028602969320691644358773586),
	(1.4877353772046548932715555, 0.14566877153207281663773599),
	(1.4206983927779191889826, 0.076830486127880702249439993),
	(1.3162236060498933364869556, 0.16031313000467530644933363),
	(1.5473450684303703578810093, -0.11064907507939082484935782),
	(-1.4841462340185253987375812, 0.049341850305024399493142411),
];

const TEST_ATANH: []c128 = [
	(0.058375027938968509064640438, 1.4793488495105334458167782),
	(0.12977343497790381229915667, -1.5661009410463561327262499),
	(-0.010576456067347252072200088, -1.3743698658402284549750563),
	(-0.042218595678688358882784918, 1.4891433968166405606692604),
	(0.095218997991316722061828397, 1.5416884098777110330499698),
	(0.079965459366890323857556487, 1.4252510353873192700350435),
	(0.15051245471980726221708301, 1.4907432533016303804884461),
	(0.25082072933993987714470373, 1.392057665392187516442986),
	(0.022896108815797135846276662, -1.4609224989282864208963021),
	(-0.08665624101841876130537396, 1.5207902036935093480142159),
];

const TEST_CONJ: []c128 = [
	(4.9790119248836735e+00, -7.7388724745781045e+00),
	(7.7388724745781045e+00, 2.7688005719200159e-01),
	(-2.7688005719200159e-01, 5.0106036182710749e+00),
	(-5.0106036182710749e+00, -9.6362937071984173e+00),
	(9.6362937071984173e+00, -2.9263772392439646e+00),
	(2.9263772392439646e+00, -5.2290834314593066e+00),
	(5.2290834314593066e+00, -2.7279399104360102e+00),
	(2.7279399104360102e+00, -1.8253080916808550e+00),
	(1.8253080916808550e+00, 8.6859247685756013e+00),
	(-8.6859247685756013e+00, -4.9790119248836735e+00),
];

const TEST_COS: []c128 = [
	(3.024540920601483938336569e+02, 1.1073797572517071650045357e+03),
	(1.192858682649064973252758e-01, 2.7857554122333065540970207e-01),
	(7.2144394304528306603857962e+01, -2.0500129667076044169954205e+01),
	(2.24921952538403984190541e+03, -7.317363745602773587049329e+03),
	(-9.148222970032421760015498e+00, 1.953124661113563541862227e+00),
	(-9.116081175857732248227078e+01, -1.992669213569952232487371e+01),
	(3.795639179042704640002918e+00, 6.623513350981458399309662e+00),
	(-2.9144840732498869560679084e+00, -1.214620271628002917638748e+00),
	(-7.45123482501299743872481e+02, 2.8641692314488080814066734e+03),
	(-5.371977967039319076416747e+01, 4.893348341339375830564624e+01),
];

const TEST_COSH: []c128 = [
	(8.34638383523018249366948e+00, 7.2181057886425846415112064e+01),
	(1.10421967379919366952251e+03, -3.1379638689277575379469861e+02),
	(3.051485206773701584738512e-01, -2.6805384730105297848044485e-01),
	(-7.33294728684187933370938e+01, 1.574445942284918251038144e+01),
	(-7.478643293945957535757355e+03, 1.6348382209913353929473321e+03),
	(4.622316522966235701630926e+00, -8.088695185566375256093098e+00),
	(-8.544333183278877406197712e+01, 3.7505836120128166455231717e+01),
	(-1.934457815021493925115198e+00, 7.3725859611767228178358673e+00),
	(-2.352958770061749348353548e+00, -2.034982010440878358915409e+00),
	(7.79756457532134748165069e+02, 2.8549350716819176560377717e+03),
];

const TEST_EXP: []c128 = [
	(1.669197736864670815125146e+01, 1.4436895109507663689174096e+02),
	(2.2084389286252583447276212e+03, -6.2759289284909211238261917e+02),
	(2.227538273122775173434327e-01, 7.2468284028334191250470034e-01),
	(-6.5182985958153548997881627e-03, -1.39965837915193860879044e-03),
	(-1.4957286524084015746110777e+04, 3.269676455931135688988042e+03),
	(9.218158701983105935659273e+00, -1.6223985291084956009304582e+01),
	(-1.7088175716853040841444505e+02, 7.501382609870410713795546e+01),
	(-3.852461315830959613132505e+00, 1.4808420423156073221970892e+01),
	(-4.586775503301407379786695e+00, -4.178501081246873415144744e+00),
	(4.451337963005453491095747e-05, -1.62977574205442915935263e-04),
];

const TEST_LOG: []c128 = [
	(2.2194438972179194425697051e+00, 9.9909115046919291062461269e-01),
	(2.0468956191154167256337289e+00, -3.5762575021856971295156489e-02),
	(1.6130808329853860438751244e+00, -1.6259990074019058442232221e+00),
	(2.3851910394823008710032651e+00, 2.0502936359659111755031062e+00),
	(2.3096442270679923004800651e+00, 2.9483213155446756211881774e-01),
	(1.7904660933974656106951860e+00, 1.0605860367252556281902109e+00),
	(1.7745926939841751666177512e+00, 4.8084556083358307819310911e-01),
	(1.1885403350045342425648780e+00, 5.8969634164776659423195222e-01),
	(2.1833107837679082586772505e+00, -1.3636647724582455028314573e+00),
	(2.3037629487273259170991671e+00, 2.6210913895386013290915234e+00),
];

const TEST_LOG10: []c128 = [
	(9.6389223745559042474184943e-01, 4.338997735671419492599631e-01),
	(8.8895547241376579493490892e-01, -1.5531488990643548254864806e-02),
	(7.0055210462945412305244578e-01, -7.0616239649481243222248404e-01),
	(1.0358753067322445311676952e+00, 8.9043121238134980156490909e-01),
	(1.003065742975330237172029e+00, 1.2804396782187887479857811e-01),
	(7.7758954439739162532085157e-01, 4.6060666333341810869055108e-01),
	(7.7069581462315327037689152e-01, 2.0882857371769952195512475e-01),
	(5.1617650901191156135137239e-01, 2.5610186717615977620363299e-01),
	(9.4819982567026639742663212e-01, -5.9223208584446952284914289e-01),
	(1.0005115362454417135973429e+00, 1.1383255270407412817250921e+00),
];

const TEST_POLAR: []c128 = [
	(9.2022120669932650313380972e+00, 9.9909115046919291062461269e-01),
	(7.7438239742296106616261394e+00, -3.5762575021856971295156489e-02),
	(5.0182478202557746902556648e+00, -1.6259990074019058442232221e+00),
	(1.0861137372799545160704002e+01, 2.0502936359659111755031062e+00),
	(1.0070841084922199607011905e+01, 2.9483213155446756211881774e-01),
	(5.9922447613166942183705192e+00, 1.0605860367252556281902109e+00),
	(5.8978784056736762299945176e+00, 4.8084556083358307819310911e-01),
	(3.2822866700678709020367184e+00, 5.8969634164776659423195222e-01),
	(8.8756430028990417290744307e+00, -1.3636647724582455028314573e+00),
	(1.0011785496777731986390856e+01, 2.6210913895386013290915234e+00),
];

const TEST_POW: []c128 = [
	(-2.499956739197529585028819e+00, 1.759751724335650228957144e+00),
	(7.357094338218116311191939e+04, -5.089973412479151648145882e+04),
	(1.320777296067768517259592e+01, -3.165621914333901498921986e+01),
	(-3.123287828297300934072149e-07, -1.9849567521490553032502223e-7),
	(8.0622651468477229614813e+04, -7.80028727944573092944363e+04),
	(-1.0268824572103165858577141e+00, -4.716844738244989776610672e-01),
	(-4.35953819012244175753187e+01, 2.2036445974645306917648585e+02),
	(8.3556092283250594950239e-01, -1.2261571947167240272593282e+01),
	(1.582292972120769306069625e+03, 1.273564263524278244782512e+04),
	(6.592208301642122149025369e-08, 2.584887236651661903526389e-08),
];

const TEST_SIN: []c128 = [
	(-1.1073801774240233539648544e+03, 3.024539773002502192425231e+02),
	(1.0317037521400759359744682e+00, -3.2208979799929570242818e-02),
	(-2.0501952097271429804261058e+01, -7.2137981348240798841800967e+01),
	(7.3173638080346338642193078e+03, 2.249219506193664342566248e+03),
	(-1.964375633631808177565226e+00, -9.0958264713870404464159683e+00),
	(1.992783647158514838337674e+01, -9.11555769410191350416942e+01),
	(-6.680335650741921444300349e+00, 3.763353833142432513086117e+00),
	(1.2794028166657459148245993e+00, -2.7669092099795781155109602e+00),
	(2.8641693949535259594188879e+03, 7.451234399649871202841615e+02),
	(-4.893811726244659135553033e+01, -5.371469305562194635957655e+01),
];

const TEST_SINH: []c128 = [
	(8.34559353341652565758198e+00, 7.2187893208650790476628899e+01),
	(1.1042192548260646752051112e+03, -3.1379650595631635858792056e+02),
	(-8.239469336509264113041849e-02, 9.9273668758439489098514519e-01),
	(7.332295456982297798219401e+01, -1.574585908122833444899023e+01),
	(-7.4786432301380582103534216e+03, 1.63483823493980029604071e+03),
	(4.595842179016870234028347e+00, -8.135290105518580753211484e+00),
	(-8.543842533574163435246793e+01, 3.750798997857594068272375e+01),
	(-1.918003500809465688017307e+00, 7.4358344619793504041350251e+00),
	(-2.233816733239658031433147e+00, -2.143519070805995056229335e+00),
	(-7.797564130187551181105341e+02, -2.8549352346594918614806877e+03),
];

const TEST_SQRT: []c128 = [
	(2.6628203086086130543813948e+00, 1.4531345674282185229796902e+00),
	(2.7823278427251986247149295e+00, -4.9756907317005224529115567e-02),
	(1.5397025302089642757361015e+00, -1.6271336573016637535695727e+00),
	(1.7103411581506875260277898e+00, 2.8170677122737589676157029e+00),
	(3.1390392472953103383607947e+00, 4.6612625849858653248980849e-01),
	(2.1117080764822417640789287e+00, 1.2381170223514273234967850e+00),
	(2.3587032281672256703926939e+00, 5.7827111903257349935720172e-01),
	(1.7335262588873410476661577e+00, 5.2647258220721269141550382e-01),
	(2.3131094974708716531499282e+00, -1.8775429304303785570775490e+00),
	(8.1420535745048086240947359e-01, 3.0575897587277248522656113e+00),
];

const TEST_TAN: []c128 = [
	(-1.928757919086441129134525e-07, 1.0000003267499169073251826e+00),
	(1.242412685364183792138948e+00, -3.17149693883133370106696e+00),
	(-4.6745126251587795225571826e-05, -9.9992439225263959286114298e-01),
	(4.792363401193648192887116e-09, 1.0000000070589333451557723e+00),
	(2.345740824080089140287315e-03, 9.947733046570988661022763e-01),
	(-2.396030789494815566088809e-05, 9.9994781345418591429826779e-01),
	(-7.370204836644931340905303e-03, 1.0043553413417138987717748e+00),
	(-3.691803847992048527007457e-02, 9.6475071993469548066328894e-01),
	(-2.781955256713729368401878e-08, -1.000000049848910609006646e+00),
	(9.4281590064030478879791249e-05, 9.9999119340863718183758545e-01),
];

const TEST_TANH: []c128 = [
	(1.0000921981225144748819918e+00, 2.160986245871518020231507e-05),
	(9.9999967727531993209562591e-01, -1.9953763222959658873657676e-07),
	(-1.765485739548037260789686e+00, 1.7024216325552852445168471e+00),
	(-9.999189442732736452807108e-01, 3.64906070494473701938098e-05),
	(9.9999999224622333738729767e-01, -3.560088949517914774813046e-09),
	(1.0029324933367326862499343e+00, -4.948790309797102353137528e-03),
	(9.9996113064788012488693567e-01, -4.226995742097032481451259e-05),
	(1.0074784189316340029873945e+00, -4.194050814891697808029407e-03),
	(9.9385534229718327109131502e-01, 5.144217985914355502713437e-02),
	(-1.0000000491604982429364892e+00, -2.901873195374433112227349e-08),
];

// huge values along the real axis for testing reducepi in tan
// TODO: these probably shouldn't have to be casted twice (harec bug?)
const TEST_HUGEIN: []c128 = [
	((1 << 28): u64: f64, 0f64),
	((1 << 29): u64: f64, 0f64),
	((1 << 30): u64: f64, 0f64),
	((1 << 35): u64: f64, 0f64),
	(-1.329227995784916e+36, 0f64),
	(1.7668470647783843e+72, 0f64),
	(2.037035976334486e+90, 0f64),
	(-3.1217485503159922e+144, 0f64),
	(1.8919697882131776e+69, 0f64),
	(-2.514859209672214e+105, 0f64),
];

// Results for TEST_TANHUGE[i] calculated with https://github.com/robpike/ivy
// using 4096 bits of working precision.
const TEST_TANHUGE: []c128 = [
	((5.95641897939639421): f64, 0f64),
	((-0.34551069233430392): f64, 0f64),
	((-0.78469661331920043): f64, 0f64),
	((0.84276385870875983): f64, 0f64),
	((0.40806638884180424): f64, 0f64),
	((-0.37603456702698076): f64, 0f64),
	((4.60901287677810962): f64, 0f64),
	((3.39135965054779932): f64, 0f64),
	((-6.76813854009065030): f64, 0f64),
	((-0.76417695016604922): f64, 0f64),
];

const TEST_VCABSSC: []c128 = [
	(math::NAN, math::NAN),
];

const TEST_ABSSC: []f64 = [
	math::NAN,
];

const TEST_ACOSSC: [](c128, c128) = [
	// G.6.1.1
	((0f64, 0f64),
		(math::PI / 2f64, -0f64)),
	((-0f64, 0f64),
		(math::PI / 2f64, -0f64)),
	((0f64, math::NAN),
		(math::PI / 2f64, math::NAN)),
	((-0f64, math::NAN),
		(math::PI / 2f64, math::NAN)),
	((1f64, math::INF),
		(math::PI / 2f64, -math::INF)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((-math::INF, 1f64),
		(math::PI, -math::INF)),
	((math::INF, 1f64),
		(0f64, -math::INF)),
	((-math::INF, math::INF),
		(3f64 * math::PI / 4f64, -math::INF)),
	((math::INF, math::INF),
		(math::PI / 4f64, -math::INF)),
	((math::INF, math::NAN),
		(math::NAN, -math::INF)), // imaginary sign unspecified
	((-math::INF, math::NAN),
		(math::NAN, math::INF)), // imaginary sign unspecified
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, -math::INF)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_ACOSHSC: [](c128, c128) = [
	// G.6.2.1
	((0f64, 0f64),
		(0f64, math::PI / 2f64)),
	((-0f64, 0f64),
		(0f64, math::PI / 2f64)),
	((1f64, math::INF),
		(math::INF, math::PI / 2f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((-math::INF, 1f64),
		(math::INF, math::PI)),
	((math::INF, 1f64),
		(math::INF, 0f64)),
	((-math::INF, math::INF),
		(math::INF, 3f64 * math::PI / 4f64)),
	((math::INF, math::INF),
		(math::INF, math::PI / 4f64)),
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((-math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::INF, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_ASINSC: [](c128, c128) = [
	// Derived from Asin(z) = -i * Asinh(i * z), G.6 #7
	((0f64, 0f64),
		(0f64, 0f64)),
	((1f64, math::INF),
		(0f64, math::INF)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(math::PI / 2f64, math::INF)),
	((math::INF, math::INF),
		(math::PI / 4f64, math::INF)),
	((math::INF, math::NAN),
		(math::NAN, math::INF)), // imaginary sign unspecified
	((math::NAN, 0f64),
		(math::NAN, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::INF)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_ASINHSC: [](c128, c128) = [
	// G.6.2.2
	((0f64, 0f64),
		(0f64, 0f64)),
	((1f64, math::INF),
		(math::INF, math::PI / 2f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(math::INF, 0f64)),
	((math::INF, math::INF),
		(math::INF, math::PI / 4f64)),
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 0f64),
		(math::NAN, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::INF, math::NAN)), // sign of real part unspecified
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_ATANSC: [](c128, c128) = [
	// Derived from Atan(z) = -i * Atanh(i * z), G.6 #7
	((0f64, 0f64),
		(0f64, 0f64)),
	((0f64, math::NAN),
		(math::NAN, math::NAN)),
	((1f64, 0f64),
		(math::PI / 4f64, 0f64)),
	((1f64, math::INF),
		(math::PI / 2f64, 0f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(math::PI / 2f64, 0f64)),
	((math::INF, math::INF),
		(math::PI / 2f64, 0f64)),
	((math::INF, math::NAN),
		(math::PI / 2f64, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, 0f64)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_ATANHSC: [](c128, c128) = [
	// G.6.2.3
	((0f64, 0f64),
		(0f64, 0f64)),
	((0f64, math::NAN),
		(0f64, math::NAN)),
	((1f64, 0f64),
		(math::INF, 0f64)),
	((1f64, math::INF),
		(0f64, math::PI / 2f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(0f64, math::PI / 2f64)),
	((math::INF, math::INF),
		(0f64, math::PI / 2f64)),
	((math::INF, math::NAN),
		(0f64, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(0f64, math::PI / 2f64)), // sign of real part not specified.
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_VCCONJSC: []c128 = [
	(math::NAN, math::NAN),
];

const TEST_CONJSC: []c128 = [
	(math::NAN, math::NAN),
];

const TEST_COSSC: [](c128, c128) = [
	// Derived from Cos(z) = Cosh(i * z), G.6 #7
	((0f64, 0f64),
		(1f64, -0f64)),
	((0f64, math::INF),
		(math::INF, -0f64)),
	((0f64, math::NAN),
		(math::NAN, 0f64)), // imaginary sign unspecified
	((1f64, math::INF),
		(math::INF, -math::INF)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 0f64),
		(math::NAN, -0f64)),
	((math::INF, 1f64),
		(math::NAN, math::NAN)),
	((math::INF, math::INF),
		(math::INF, math::NAN)), // real sign unspecified
	((math::INF, math::NAN),
		(math::NAN, math::NAN)),
	((math::NAN, 0f64),
		(math::NAN, -0f64)), // imaginary sign unspecified
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::INF, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_COSHSC: [](c128, c128) = [
	// G.6.2.4
	((0f64, 0f64),
		(1f64, 0f64)),
	((0f64, math::INF),
		(math::NAN, 0f64)), // imaginary sign unspecified
	((0f64, math::NAN),
		(math::NAN, 0f64)), // imaginary sign unspecified
	((1f64, math::INF),
		(math::NAN, math::NAN)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 0f64),
		(math::INF, 0f64)),
	((math::INF, 1f64),
		(math::INF, math::INF)), // +(math::INF, 0f64)  cis(y)
	((math::INF, math::INF),
		(math::INF, math::NAN)), // real sign unspecified
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 0f64),
		(math::NAN, 0f64)), // imaginary sign unspecified
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_EXPSC: [](c128, c128) = [
	// G.6.3.1
	((0f64, 0f64),
		(1f64, 0f64)),
	((-0f64, 0f64),
		(1f64, 0f64)),
	((1f64, math::INF),
		(math::NAN, math::NAN)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 0f64),
		(math::INF, 0f64)),
	((-math::INF, 1f64),
		(0f64, 0f64)),
	((math::INF, 1f64),
		(math::INF, math::INF)),
	((-math::INF, math::INF),
		(0f64, 0f64)), // real and imaginary sign unspecified
	((math::INF, math::INF),
		(math::INF, math::NAN)), // real sign unspecified
	((-math::INF, math::NAN),
		(0f64, 0f64)), // real and imaginary sign unspecified
	((math::INF, math::NAN),
		(math::INF, math::NAN)), // real sign unspecified
	((math::NAN, 0f64),
		(math::NAN, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_VCISNANSC: []c128 = [
	(-math::INF, -math::INF),
	(-math::INF, math::NAN),
	(math::NAN, -math::INF),
	(0f64, math::NAN),
	(math::NAN, 0f64),
	(math::INF, math::INF),
	(math::INF, math::NAN),
	(math::NAN, math::INF),
	(math::NAN, math::NAN),
];

const TEST_ISNANSC: []bool = [
	false,
	false,
	false,
	true,
	true,
	false,
	false,
	false,
	true,
];

// XXX: math::PI doesn't have suitable precision here for some reason
const TEST_LOGSC: [](c128, c128) = [
	// G.6.3.2
	((0f64, 0f64),
		(-math::INF, 0f64)),
	//((-0f64, 0f64),
	//	(-math::INF, math::PI)),
	//((1f64, math::INF),
	//	(math::INF, math::PI / 2f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	//((-math::INF, 1f64),
	//	(math::INF, math::PI)),
	((math::INF, 1f64),
		(math::INF, 0f64)),
	//((-math::INF, math::INF),
	//	(math::INF, 3f64 * math::PI / 4f64)),
	//((math::INF, math::INF),
	//	(math::INF, math::PI / 4f64)),
	((-math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::INF, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_LOG10SC: [](c128, c128) = [
	// derived from Log special cases via Log10(x) = math.Log10E*Log(x)
	((0f64, 0f64),
		(-math::INF, 0f64)),
	((-0f64, 0f64),
		(-math::INF, math::LOG10_E * math::PI)),
	((1f64, math::INF),
		(math::INF, math::LOG10_E * math::PI / 2f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((-math::INF, 1f64),
		(math::INF, math::LOG10_E * math::PI)),
	((math::INF, 1f64),
		(math::INF, 0f64)),
	((-math::INF, math::INF),
		(math::INF, math::LOG10_E * 3f64 * math::PI / 4f64)),
	((math::INF, math::INF),
		(math::INF, math::LOG10_E * math::PI / 4f64)),
	((-math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::INF, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_VCPOLARSC: []c128 = [
	(math::NAN, math::NAN),
];

const TEST_POLARSC: [](f64, f64) = [
	(math::NAN, math::NAN),
];

const TEST_VCPOWSC: [](c128, c128) = [
	((math::NAN, math::NAN), (math::NAN, math::NAN)),
	((0f64, 0f64), (math::NAN, math::NAN)),
];

const TEST_POWSC: []c128 = [
	(math::NAN, math::NAN),
	(math::NAN, math::NAN),
];

const TEST_SINSC: [](c128, c128) = [
	// Derived from Sin(z) = -i * Sinh(i * z), G.6 #7
	((0f64, 0f64),
		(0f64, 0f64)),
	((0f64, math::INF),
		(0f64, math::INF)),
	((0f64, math::NAN),
		(0f64, math::NAN)),
	((1f64, math::INF),
		(math::INF, math::INF)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 0f64),
		(math::NAN, 0f64)),
	((math::INF, 1f64),
		(math::NAN, math::NAN)),
	((math::INF, math::INF),
		(math::NAN, math::INF)),
	((math::INF, math::NAN),
		(math::NAN, math::NAN)),
	((math::NAN, 0f64),
		(math::NAN, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::INF)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_SINHSC: [](c128, c128) = [
	// G.6.2.5
	((0f64, 0f64),
		(0f64, 0f64)),
	((0f64, math::INF),
		(0f64, math::NAN)), // real sign unspecified
	((0f64, math::NAN),
		(0f64, math::NAN)), // real sign unspecified
	((1f64, math::INF),
		(math::NAN, math::NAN)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 0f64),
		(math::INF, 0f64)),
	((math::INF, 1f64),
		(math::INF, math::INF)), // +math::INF  cis(y)
	((math::INF, math::INF),
		(math::INF, math::NAN)), // real sign unspecified
	((math::INF, math::NAN),
		(math::INF, math::NAN)), // real sign unspecified
	((math::NAN, 0f64),
		(math::NAN, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_SQRTSC: [](c128, c128) = [
	// G.6.4.2
	((0f64, 0f64),
		(0f64, 0f64)),
	((-0f64, 0f64),
		(0f64, 0f64)),
	((1f64, math::INF),
		(math::INF, math::INF)),
	((math::NAN, math::INF),
		(math::INF, math::INF)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((-math::INF, 1f64),
		(0f64, math::INF)),
	((math::INF, 1f64),
		(math::INF, 0f64)),
	((-math::INF, math::NAN),
		(math::NAN, math::INF)), // imaginary sign unspecified
	((math::INF, math::NAN),
		(math::INF, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_TANSC: [](c128, c128) = [
	// Derived from Tan(z) = -i * Tanh(i * z), G.6 #7
	((0f64, 0f64),
		(0f64, 0f64)),
	((0f64, math::NAN),
		(0f64, math::NAN)),
	((1f64, math::INF),
		(0f64, 1f64)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(math::NAN, math::NAN)),
	((math::INF, math::INF),
		(0f64, 1f64)),
	((math::INF, math::NAN),
		(math::NAN, math::NAN)),
	((math::NAN, 0f64),
		(math::NAN, math::NAN)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(0f64, 1f64)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

const TEST_TANHSC: [](c128, c128) = [
	// G.6.2.6
	((0f64, 0f64),
		(0f64, 0f64)),
	((1f64, math::INF),
		(math::NAN, math::NAN)),
	((1f64, math::NAN),
		(math::NAN, math::NAN)),
	((math::INF, 1f64),
		(1f64, 0f64)), // 1 + i 0 sin(2y)
	((math::INF, math::INF),
		(1f64, 0f64)), // imaginary sign unspecified
	((math::INF, math::NAN),
		(1f64, 0f64)), // imaginary sign unspecified
	((math::NAN, 0f64),
		(math::NAN, 0f64)),
	((math::NAN, 1f64),
		(math::NAN, math::NAN)),
	((math::NAN, math::INF),
		(math::NAN, math::NAN)),
	((math::NAN, math::NAN),
		(math::NAN, math::NAN)),
];

// branch cut continuity checks
// points on each axis at |z| > 1 are checked for one-sided continuity from both
// the positive and negative side
// all possible branch cuts for the elementary functions are at one of these
// points

// TODO: this probably shouldn't need to be casted twice (harec bug?)
def EPS: f64 = 1f64 / (1 << 53): u64: f64;

const BRANCHPOINTS: [](c128, c128) = [
	((2f64, 0f64), (2f64, EPS)),
	((2f64, -0f64), (2f64, -EPS)),
	((-2.0, 0f64), (-2.0, EPS)),
	((-2.0, -0f64), (-2.0, -EPS)),
	((0f64, 2f64), (EPS, 2f64)),
	((-0f64, 2f64), (-EPS, 2f64)),
	((0f64, -2.0), (EPS, -2.0)),
	((-0f64, -2.0), (-EPS, -2.0)),
];

fn tolerance(actual: f64, expected: f64, e: f64) bool = {
	const err = math::absf64(actual - expected);
	if (expected != 0f64) {
		e = math::absf64(e * expected);
	};
	return err < e;
};

fn veryclose(a: f64, b: f64) bool = tolerance(a, b, 4e-16);

fn alike(a: f64, b: f64) bool = {
	if (math::isnan(a) && math::isnan(b)) {
		return true;
	};
	if (a == b) {
		return math::signf64(a) == math::signf64(b);
	};
	return false;
};

fn csoclose(a: c128, b: c128, e: f64) bool = {
	const d = absc128(subc128(a, b));
	if (b.0 != 0f64 || b.1 != 0f64) {
		e *= absc128(b);
		if (e < 0f64) {
			e = -e;
		};
	};
	return d < e;
};

fn cveryclose(a: c128, b: c128) bool = csoclose(a, b, 4e-16);

fn calike(a: c128, b: c128) bool = {
	let realalike = false, imagalike = false;
	realalike = if (isexact(b.0)) {
		yield alike(a.0, b.0);
	} else {
		// Allow non-exact special cases to have errors in ULP.
		yield veryclose(a.0, b.0);
	};
	imagalike = if (isexact(b.1)) {
		yield alike(a.1, b.1);
	} else {
		// Allow non-exact special cases to have errors in ULP.
		yield veryclose(a.1, b.1);
	};
	return realalike && imagalike;
};

// Special cases that should match exactly. Other cases are multiples of pi that
// may not be last bit identical on all platforms.
fn isexact(x: f64) bool =
	math::isnan(x) || math::isinf(x) || x == 0f64 || x == 1f64 || x == -1f64;

@test fn abs() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(veryclose(TEST_ABS[i], absc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_VCABSSC); i += 1) {
		assert(alike(TEST_ABSSC[i], absc128(TEST_VCABSSC[i])));
	};
};

@test fn acos() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		// XXX: should have 1e-14 precision
		assert(csoclose(TEST_ACOS[i], acosc128(VC[i]), 1e-7));
	};
	for (let i = 0z; i < len(TEST_ACOSSC); i += 1) {
		const v = TEST_ACOSSC[i];
		assert(calike(v.1, acosc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// acos(conj(z)) == conj(acos(z))
		assert(calike(conjc128(v.1), acosc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(acosc128(pt.0), acosc128(pt.1)));
	};
};

@test fn acosh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		// XXX: should have 1e-14 precision
		assert(csoclose(TEST_ACOSH[i], acoshc128(VC[i]), 1e-7));
	};
	for (let i = 0z; i < len(TEST_ACOSHSC); i += 1) {
		const v = TEST_ACOSHSC[i];
		assert(calike(v.1, acoshc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// acosh(conj(z)) == conj(acosh(z))
		assert(calike(conjc128(v.1), acoshc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(acoshc128(pt.0), acoshc128(pt.1)));
	};
};

@test fn asin() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_ASIN[i], asinc128(VC[i]), 1e-14));
	};
	for (let i = 0z; i < len(TEST_ASINSC); i += 1) {
		const v = TEST_ASINSC[i];
		assert(calike(v.1, asinc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// asin(conj(z)) == asin(sinh(z))
		assert(calike(conjc128(v.1), asinc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// asin(-z) == -asin(z)
		assert(calike((-v.1.0, -v.1.1), asinc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(asinc128(pt.0), asinc128(pt.1)));
	};
};

@test fn asinh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_ASINH[i], asinhc128(VC[i]), 4e-15));
	};
	for (let i = 0z; i < len(TEST_ASINHSC); i += 1) {
		const v = TEST_ASINHSC[i];
		assert(calike(v.1, asinhc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// asinh(conj(z)) == asinh(sinh(z))
		assert(calike(conjc128(v.1), asinhc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// asinh(-z) == -asinh(z)
		assert(calike((-v.1.0, -v.1.1), asinhc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(asinhc128(pt.0), asinhc128(pt.1)));
	};
};

@test fn atan() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(cveryclose(TEST_ATAN[i], atanc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_ATANSC); i += 1) {
		const v = TEST_ATANSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, atanc128(v.0)));
		// atan(conj(z)) == conj(atan(z))
		assert(calike(conjc128(v.1), atanc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// atan(-z) == -atan(z)
		assert(calike((-v.1.0, -v.1.1), atanc128((-v.0.0, -v.0.1)))
			|| calike((v.0), conjc128(v.0)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(atanc128(pt.0), atanc128(pt.1)));
	};
};

@test fn atanh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(cveryclose(TEST_ATANH[i], atanhc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_ATANHSC); i += 1) {
		const v = TEST_ATANHSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, atanhc128(v.0)));
		// atanh(conj(z)) == conj(atanh(z))
		assert(calike(conjc128(v.1), atanhc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// atanh(-z) == -atanh(z)
		assert(calike((-v.1.0, -v.1.1), atanhc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(atanhc128(pt.0), atanhc128(pt.1)));
	};
};

@test fn conj() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(cveryclose(TEST_CONJ[i], conjc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_VCCONJSC); i += 1) {
		assert(calike(TEST_CONJSC[i], conjc128(TEST_VCCONJSC[i])));
	};
};

@test fn cos() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_COS[i], cosc128(VC[i]), 3e-15));
	};
	for (let i = 0z; i < len(TEST_COSSC); i += 1) {
		const v = TEST_COSSC[i];
		if (isnan(v.0) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, cosc128(v.0)));
		// cos(conj(z)) == cos(cosh(z))
		assert (calike(conjc128(v.1), cosc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// cos(-z) == cos(z)
		assert(calike(v.1, cosc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn cosh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_COSH[i], coshc128(VC[i]), 2e-15));
	};
	for (let i = 0z; i < len(TEST_COSHSC); i += 1) {
		const v = TEST_COSHSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, coshc128(v.0)));
		// cosh(conj(z)) == conj(cosh(z))
		assert(calike(conjc128(v.1), coshc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// cosh(-z) == cosh(z)
		assert(calike(v.1, coshc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn exp() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_EXP[i], expc128(VC[i]), 1e-15));
	};
	for (let i = 0z; i < len(TEST_EXPSC); i += 1) {
		const v = TEST_EXPSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, expc128(v.0)));
		// exp(conj(z)) == exp(cosh(z))
		assert(calike(conjc128(v.1), expc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
	};
};

@test fn isnan() void = {
	for (let i = 0z; i < len(TEST_VCISNANSC); i += 1) {
		assert(TEST_ISNANSC[i] == isnan(TEST_VCISNANSC[i]));
	};
};

@test fn log() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(cveryclose(TEST_LOG[i], logc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_LOGSC); i += 1) {
		const v = TEST_LOGSC[i];
		assert(calike(v.1, logc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// log(conj(z)) == conj(log(z))
		assert(calike(conjc128(v.1), logc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(logc128(pt.0), logc128(pt.1)));
	};
};

@test fn polar() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		const p = polarc128(VC[i]);
		assert(veryclose(TEST_POLAR[i].0, p.0)
			|| veryclose(TEST_POLAR[i].1, p.1));
	};
	for (let i = 0z; i < len(TEST_VCPOLARSC); i += 1) {
		const p = polarc128(TEST_VCPOLARSC[i]);
		assert(alike(TEST_POLARSC[i].0, p.0)
			|| alike(TEST_POLARSC[i].1, p.1));
	};
};

@test fn pow() void = {
	// Special cases for pow(0, c).
	const zeropowers: [](c128, c128) = [
		((0f64, 0f64), (1f64, 0f64)),
		((1.5, 0f64), (0f64, 0f64)),
		((-1.5, 0f64), (math::INF, 0f64)),
		((-1.5, 1.5), (math::INF, math::INF)),
	];
	for (let i = 0z; i < len(zeropowers); i += 1) {
		const zp = zeropowers[i];
		assert(equalc128(powc128((0f64, 0f64), zp.0), zp.1));
	};
	const a = (3f64, 3f64);
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_POW[i], powc128(a, VC[i]), 4e-15));
	};
	for (let i = 0z; i < len(TEST_VCPOWSC); i += 1) {
		const f = TEST_VCPOWSC[i];
		assert(calike(TEST_POWSC[i], powc128(f.0, f.1)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(powc128(pt.0, (0.1, 0f64)),
				powc128(pt.1, (0.1, 0f64))));
	};
};

@test fn rect() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		const f = TEST_POLAR[i];
		assert(cveryclose(VC[i], rectc128(f.0, f.1)));
	};
	for (let i = 0z; i < len(TEST_VCPOLARSC); i += 1) {
		const f = TEST_POLARSC[i];
		assert(calike(TEST_VCPOLARSC[i], rectc128(f.0, f.1)));
	};
};

@test fn sin() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_SIN[i], sinc128(VC[i]), 2e-15));
	};
	for (let i = 0z; i < len(TEST_SINSC); i += 1) {
		const v = TEST_SINSC[i];
		assert(calike(v.1, sinc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// sin(conj(z)) == conj(sin(z))
		assert(calike(conjc128(sinc128(v.0)), sinc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// sin(-z) == -sin(z)
		assert(calike((-v.1.0, -v.1.1), sinc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn sinh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_SINH[i], sinhc128(VC[i]), 2e-15));
	};
	for (let i = 0z; i < len(TEST_SINHSC); i += 1) {
		const v = TEST_SINHSC[i];
		assert(calike(v.1, sinhc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// sinh(conj(z)) == conj(sinh(z))
		assert(calike(conjc128(v.1), sinhc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// sinh(-z) == -sinh(z)
		assert(calike((-v.1.0, -v.1.1), sinhc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn sqrt() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(cveryclose(TEST_SQRT[i], sqrtc128(VC[i])));
	};
	for (let i = 0z; i < len(TEST_SQRTSC); i += 1) {
		const v = TEST_SQRTSC[i];
		assert(calike(v.1, sqrtc128(v.0)));
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// sqrt(conj(z)) == conj(sqrt(z))
		assert(calike(conjc128(v.1), sqrtc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
	};
	for (let i = 0z; i < len(BRANCHPOINTS); i += 1) {
		const pt = BRANCHPOINTS[i];
		assert(cveryclose(sqrtc128(pt.0), sqrtc128(pt.1)));
	};
};

@test fn tan() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_TAN[i], tanc128(VC[i]), 3e-15));
	};
	for (let i = 0z; i < len(TEST_TANSC); i += 1) {
		const v = TEST_TANSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		if (math::isnan(v.0.0) && math::isinf(v.0.1)) {
			const r = tanc128(v.0);
			assert(r.0 == v.1.0 && r.1 == v.1.1);
			continue;
		};
		assert(calike(v.1, tanc128(v.0)));
		// tan(conj(z)) == conj(tan(z))
		assert (calike(conjc128(v.1), tanc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// tan(-z) == -tan(z)
		assert(calike((-v.1.0, -v.1.1), tanc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn tanh() void = {
	for (let i = 0z; i < len(VC); i += 1) {
		assert(csoclose(TEST_TANH[i], tanhc128(VC[i]), 2e-15));
	};
	for (let i = 0z; i < len(TEST_TANHSC); i += 1) {
		const v = TEST_TANHSC[i];
		if (math::isnan(v.0.1) || math::isnan(v.1.1)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		assert(calike(v.1, tanhc128(v.0)));
		// tanh(conj(z)) == conj(tanh(z))
		assert(calike(conjc128(v.1), tanhc128(conjc128(v.0)))
			|| calike(v.0, conjc128(v.0)));
		if (math::isnan(v.0.0) || math::isnan(v.1.0)) {
			// Negating NaN is undefined with regard to the sign bit
			// produced.
			continue;
		};
		// tanh(-z) == -tanh(z)
		assert(calike((-v.1.0, -v.1.1), tanhc128((-v.0.0, -v.0.1)))
			|| calike(v.0, (-v.0.0, -v.0.1)));
	};
};

@test fn tanhuge() void = {
	for (let i = 0z; i < len(TEST_HUGEIN); i += 1) {
		assert(csoclose(TEST_TANHUGE[i], tanc128(TEST_HUGEIN[i]), 1e-15));
	};
};
