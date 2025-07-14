using CSV
using DataFrames
using HTTP
using JSON3
using TOML

token = ENV["GITHUB_PAT"] 

function extract_usernames(base_dir::String)
    usernames = String[]
    
    for (root, dirs, files) in walkdir(base_dir)
        for file in files
            if file == "Package.toml"
                pkg = TOML.parsefile(joinpath(root, file))
                if haskey(pkg, "repo")
                    m = match(r"github\.com/([^/]+)/", pkg["repo"])
                    if m !== nothing
                        push!(usernames, m.captures[1])
                    end
                end
            end
        end
    end
    
    return unique(usernames)
end

function is_org(username::String, token::String)
    url = "https://api.github.com/users/$username"
    headers = ["Authorization" => "token $token", "User-Agent" => "JuliaScript"]
    
    try
        response = HTTP.get(url, headers)
        data = JSON3.read(String(response.body))
        return haskey(data, :type) ? data[:type] == "Organization" : missing
    catch e
        if e isa HTTP.Exceptions.StatusError && e.status == 404
            return missing  # User not found
        else
            @warn "Error checking user $username: $e"
            return missing
        end
    end
end

function get_user_org_dataframe(base_dir::String, token::String)
    usernames = extract_usernames(base_dir)
    
    # Check organization status for each user
    is_organization = [is_org(user, token) for user in usernames]
    
    return DataFrame(
        user_name = usernames,
        is_organization = is_organization
    )
end

# Usage
df = get_user_org_dataframe("/Users/technocrat/projects/General", token)
dropmissing!(df)
sort!(df, :user_name)
organs = subset(df, :is_organization => ByRow(x -> x == true))
pretty_table(organs, backend = Val(:text), crop = :none)
CSV.write("data/organs.csv", organs)
"""
using CSV
using DataFrames
using HTTP
using JSON3
using TOML

token = ENV["GITHUB_PAT"] 

function extract_usernames(base_dir::String)
    usernames = String[]
    
    for (root, dirs, files) in walkdir(base_dir)
        for file in files
            if file == "Package.toml"
                pkg = TOML.parsefile(joinpath(root, file))
                if haskey(pkg, "repo")
                    m = match(r"github\.com/([^/]+)/", pkg["repo"])
                    if m !== nothing
                        push!(usernames, m.captures[1])
                    end
                end
            end
        end
    end
    
    return unique(usernames)
end

function is_org(username::String, token::String)
    url = "https://api.github.com/users/$username"
    headers = ["Authorization" => "token $token", "User-Agent" => "JuliaScript"]
    
    try
        response = HTTP.get(url, headers)
        data = JSON3.read(String(response.body))
        return haskey(data, :type) ? data[:type] == "Organization" : missing
    catch e
        if e isa HTTP.Exceptions.StatusError && e.status == 404
            return missing  # User not found
        else
            @warn "Error checking user $username: $e"
            return missing
        end
    end
end

function get_user_org_dataframe(base_dir::String, token::String)
    usernames = extract_usernames(base_dir)
    
    # Check organization status for each user
    is_organization = [is_org(user, token) for user in usernames]
    
    return DataFrame(
        user_name = usernames,
        is_organization = is_organization
    )
end

# Usage
df = get_user_org_dataframe("/Users/technocrat/projects/General", token)
dropmissing!(df)
sort!(df, :user_name)
organs = subset(df, :is_organization => ByRow(x -> x == true))
pretty_table(organs, backend = Val(:text), crop = :none)
CSV.write("data/organs.csv", organs)
"""
user_name,is_organization
ACEsuit,true
ANL-CEEESA,true
ASML-Labs,true
ATISLabs,true
Actuarial-Sciences-for-Africa-ASA,true
Adgnitio,true
AlgebraicGeometricModeling,true
AlgebraicJulia,true
Algocircle,true
Argonne-National-Laboratory,true
ArndtLab,true
Astroshaper,true
AtelierArith,true
AutomationLabs-sh,true
BBN-Q,true
BGU-CS-VIL,true
BRAIN-TO,true
BattMoTeam,true
BattModels,true
BayesianRL,true
BioJulia,true
BottomHoleAssemblyAnalysis,true
Brody-Lab,true
Bytez-com,true
CEED,true
CLeARoboticsLab,true
COBREXA,true
COMODO-research,true
CTUAvastLab,true
CU-ADCL,true
CUPofTEAproject,true
CalculustJL,true
Cambridge-Control-Lab,true
Cervest,true
Chemellia,true
ChevronETC,true
ChifiSource,true
ChitambarLab,true
Circo-dev,true
Circuitscape,true
ClapeyronThermo,true
CliMA,true
ClimFlows,true
ClimateMARGO,true
CloudQuantumSim,true
CoReACTER,true
Collegeville,true
ComputableDAGs,true
ComputationalPsychiatry,true
ComputationalThermodynamics,true
ConScape,true
ControlLTH,true
CoolProp,true
CosmologicalEmulators,true
CryoGrid,true
CrystallineOrg,true
Cthonios,true
CurricularAnalytics,true
DCMLab,true
DEEPDIP-project,true
DENG-MIT,true
DJ4Earth,true
DLR-AMR,true
DOCYET,true
DanceJL,true
Datax-package,true
DecisionMakingAI,true
DeloitteOptimalReality,true
Deltares,true
Deltares-research,true
DenisTitovLab,true
DynamicsUFPR,true
DynareJulia,true
EHTJulia,true
EPFL-LAPD,true
EPOC-NZ,true
EarthSciML,true
EarthyScience,true
Eawag-SIAM,true
EchoJulia,true
EcoJulia,true
EconForge,true
Electa-Git,true
Energy-MAC,true
EnergyModelsX,true
EnzymeAD,true
EpistasisLab,true
EtherSPH,true
Evovest,true
ExoJulia,true
Experica,true
FAIRDataPipeline,true
FAST-ASR,true
FRBNY-DSGE,true
FZJ-PGI-12,true
FastBEAST,true
FermiQC,true
Ferrite-FEM,true
FinancialDSL,true
FixedEffects,true
FluxML,true
FourierFlows,true
FugroRoames,true
FuzzifiED,true
GAMS-dev,true
GLCS,true
GMLC-TDC,true
GalerkinToolkit,true
GasChromatographyToolbox,true
GenericMappingTools,true
GenieFramework,true
GeoRegionsEcosystem,true
GeoscienceAustralia,true
GiovineItalia,true
Gowerlabs,true
HAMMERHEAD-Space,true
HCMID,true
HIT-UOI-SR,true
HPMolSim,true
HSU-ANT,true
HaeffnerLab,true
HapponomyOrg,true
HartreeFoca,true
Herb-AI,true
HespanhaPublic,true
HighDimensionalEconLab,true
HolyLab,true
HomodyneCT,true
HopTB,true
HorribleSanity,true
Humans-of-Julia,true
IBM,true
ICHEC,true
IHPSystems,true
IQVIA-ML,true
ITA-Solar,true
ITensor,true
Image-X-Institute,true
ImperialCollegeLondon,true
InPhyT,true
InboundsArrays,true
IntegralEquations,true
JEngTherm,true
JSBSim-Team,true
JagsJulia,true
JaneliaSciComp,true
Joseki-jl,true
Ju-jl,true
JuDO-dev,true
JulHoltzDevelopers,true
Julia-BEAST-utils,true
Julia-Tempering,true
Julia-XAI,true
Julia-i18n,true
JuliaAI,true
JuliaAPlavin,true
JuliaActors,true
JuliaActuary,true
JuliaAlgebra,true
JuliaAnimators,true
JuliaApproximation,true
JuliaArbTypes,true
JuliaArrays,true
JuliaAstro,true
JuliaAstroSim,true
JuliaAtoms,true
JuliaAttic,true
JuliaAudio,true
JuliaBallArithmetic,true
JuliaBerry,true
JuliaBesties,true
JuliaBinaryWrappers,true
JuliaBooks,true
JuliaCI,true
JuliaCJK,true
JuliaCN,true
JuliaClimate,true
JuliaCloud,true
JuliaCollections,true
JuliaCompilerPlugins,true
JuliaComputing,true
JuliaCon,true
JuliaConcurrent,true
JuliaConstraints,true
JuliaContainerization,true
JuliaControl,true
JuliaCrypto,true
JuliaCutCell,true
JuliaDDM,true
JuliaDSP,true
JuliaData,true
JuliaDataCubes,true
JuliaDatabases,true
JuliaDebug,true
JuliaDecisionFocusedLearning,true
JuliaDiff,true
JuliaDiffinDiffs,true
JuliaDiffusionBayes,true
JuliaDocs,true
JuliaDynamics,true
JuliaEDA,true
JuliaEarth,true
JuliaEcosystem,true
JuliaEnergy,true
JuliaExtremes,true
JuliaFEM,true
JuliaFinance,true
JuliaFirstOrder,true
JuliaFolds,true
JuliaFolds2,true
JuliaFunctional,true
JuliaFusion,true
JuliaGL,true
JuliaGNI,true
JuliaGNSS,true
JuliaGPU,true
JuliaGameTheoreticPlanning,true
JuliaGaussianProcesses,true
JuliaGenAI,true
JuliaGeo,true
JuliaGeochronology,true
JuliaGeodynamics,true
JuliaGeometry,true
JuliaGizmos,true
JuliaGraphics,true
JuliaGraphs,true
JuliaGtk,true
JuliaHCI,true
JuliaHEP,true
JuliaHealth,true
JuliaHolomorphic,true
JuliaHomotopyContinuation,true
JuliaIBPM,true
JuliaIO,true
JuliaIPU,true
JuliaImGui,true
JuliaImageRecon,true
JuliaImages,true
JuliaInterop,true
JuliaIntervals,true
JuliaInv,true
JuliaKit,true
JuliaLLVM,true
JuliaLabs,true
JuliaLang,true
JuliaLangSlack,true
JuliaLinearAlgebra,true
JuliaLogging,true
JuliaML,true
JuliaManifolds,true
JuliaMatSci,true
JuliaMath,true
JuliaMeshless,true
JuliaMessaging,true
JuliaMicroscopy,true
JuliaMixedModels,true
JuliaMolSim,true
JuliaMultimedia,true
JuliaMusic,true
JuliaNLSolvers,true
JuliaNeighbors,true
JuliaNeuralGraphics,true
JuliaNeuroscience,true
JuliaNonconvex,true
JuliaORNL,true
JuliaObjects,true
JuliaOcean,true
JuliaOpt,true
JuliaOptics,true
JuliaOptimalTransport,true
JuliaPOMDP,true
JuliaPackaging,true
JuliaParallel,true
JuliaPerf,true
JuliaPhylo,true
JuliaPhysics,true
JuliaPlanners,true
JuliaPlasma,true
JuliaPlots,true
JuliaPluto,true
JuliaPokemonGO,true
JuliaPolyhedra,true
JuliaPostgresORM,true
JuliaPreludes,true
JuliaPsychometrics,true
JuliaPsychometricsBazaar,true
JuliaPy,true
JuliaQUBO,true
JuliaQX,true
JuliaQuant,true
JuliaQuantumControl,true
JuliaRCM,true
JuliaRandom,true
JuliaReach,true
JuliaRecsys,true
JuliaReducePkg,true
JuliaRegistries,true
JuliaReinforcementLearning,true
JuliaRemoteSensing,true
JuliaReverse,true
JuliaRheology,true
JuliaRoadmap,true
JuliaRobotics,true
JuliaSIMD,true
JuliaSMLM,true
JuliaSatcomFramework,true
JuliaSeismo,true
JuliaServices,true
JuliaSmoothOptimizers,true
JuliaSpace,true
JuliaSpaceMissionDesign,true
JuliaSpacePhysics,true
JuliaSparse,true
JuliaStaging,true
JuliaStats,true
JuliaStochOpt,true
JuliaString,true
JuliaStrings,true
JuliaSurv,true
JuliaSymbolics,true
JuliaTDA,true
JuliaTeX,true
JuliaTelecom,true
JuliaTesting,true
JuliaText,true
JuliaTime,true
JuliaTopOpt,true
JuliaTrustworthyAI,true
JuliaTurkuDataScience,true
JuliaVTK,true
JuliaVersionControl,true
JuliaVlasov,true
JuliaWGPU,true
JuliaWTF,true
JuliaWaveScattering,true
JuliaWeb,true
JunoLab,true
KAIST-ELST,true
KDL-umass,true
KM3NeT,true
KNU-MATH-AI,true
Kirusifix,true
KnetML,true
LAMDA-POMDP,true
LAMPSPUC,true
LCSB-BioCore,true
LICO-labs,true
LandslideSIM,true
LiScI-Lab,true
LidkeLab,true
Lonero-Team,true
LouLouLibs,true
LupoLab,true
LuxDL,true
MHDFlows,true
MIT-AI-Accelerator,true
MIT-LAE,true
MOSEK,true
MPF-Optimization-Laboratory,true
MaRDI4NFDI,true
MadNLP,true
MagneticParticleImaging,true
MagneticResonanceImaging,true
MagneticSimulation,true
MakieOrg,true
MeasureTransport,true
MechanicalRabbit,true
Merck,true
Metalenz,true
Microgrids-X,true
MinFEM,true
MindTheGap-ERC,true
MineralsCloud,true
ModiaSim,true
MolarVerse,true
MolloiLab,true
MonumoLtd,true
MultivariatePolynomialSystems,true
MurrellGroup,true
NASA-SW-VnV,true
NERSC,true
NETSTOCK,true
NFFT,true
NREL,true
NREL-Sienna,true
NavAbility,true
Nemocas,true
Neuroblox,true
NonequilibriumDynamics,true
NordicMRspine,true
NumSoftware,true
NumericalMathematics,true
ODINN-SciML,true
OFAI,true
OFFIS-DAI,true
OML-NPA,true
ONSAS,true
OceanBioME,true
OpenMDAO,true
OpenMendel,true
OpenModelica,true
OpenSesame,true
OpenSourceAWE,true
OpenThermochronology,true
OptimalBranching,true
OptimalDesignLab,true
OptimalTransportNetworks,true
Optomatica,true
Orchard-Ultrasound-Innovation,true
OrchardLANL,true
OutlierDetectionJL,true
OxygenFramework,true
PALEOtoolkit,true
PIK-ICoNe,true
PSORLab,true
PTsolvers,true
PainterQubits,true
PalmStudio,true
ParallelGSReg,true
PartitionedArrays,true
PdIPS,true
PeaceFounder,true
Physics-Simulations,true
PingThingsIO,true
PlatformAwareProgramming,true
PoisotLab,true
PowerSense,true
Presage-Group,true
PrincipalMomentAnalysis,true
ProjectTorreyPines,true
PtFEM,true
PumasAI,true
PyCubed-Mini,true
PyGNC,true
QEDjl-project,true
QSI-BAQS,true
Qaintum,true
QuEraComputing,true
QuanEstimation,true
QuantEcon,true
Quantum-Many-Body,true
QuantumBFS,true
QuantumEngineeredSystems,true
QuantumKitHub,true
QuantumSavory,true
RFspin,true
RadiativeTransfer,true
RePsychLing,true
ReactionMechanismGenerator,true
ReactiveBayes,true
RegressionAndOtherStoriesJulia,true
RelationalAI,true
RelationalAI-oss,true
ReliableTeam,true
RemoteSensingTools,true
RimuQMC,true
RiskAverseRL,true
RiskLabAI,true
RoboticExplorationLab,true
RvSpectML,true
SDS-EPFL,true
SINTEF,true
SINTEF-Power-system-asset-management,true
SMG2S,true
SPSUnipi,true
STARS-Data-Fusion,true
STOR-i,true
SaguaroCapital,true
SchisslerGroup,true
SciFracX,true
SciML,true
SciQLop,true
SeisSol,true
SeismicJulia,true
ShipMMG,true
SmartTensors,true
SmoQySuite,true
SnowflurrySDK,true
Solcast,true
SolverStoppingJulia,true
SpM-lab,true
SpeedyWeather,true
SpikingNetwork,true
SpinDoctorMRI,true
StanJulia,true
Stanford-Condensed-Matter-Theory-Group,true
StatisticalRethinkingJulia,true
StellaOrg,true
Stellenbosch-Econometrics,true
StructJuMP,true
StructuralEquationModels,true
SuiteSplines,true
SunnySuite,true
Suzhou-Tongyuan,true
SymbolicML,true
TARGENE,true
TEOS-10,true
THM-MoTE,true
TMIP-code,true
TRACER-LULab,true
TRIImaging,true
TabbenBenchmark,true
Taller-de-Sasha,true
Team-RADDISH,true
TensorBFS,true
The-Lammert-Lab,true
TheDisorderedOrganization,true
Theoretical-Neuroscience-Group,true
TidierOrg,true
ToposInstitute,true
Tractables,true
TulipaEnergy,true
TuringLang,true
TypedMatrices,true
UCD4IDS,true
UCLA-StarAI,true
UCLAMAEThreads,true
UM-Bridge,true
UM-PEPL,true
USCqserver,true
USU-Analytics-Solution-Center,true
UW-PHARM,true
UncertainLab,true
UniStuttgart-IKR,true
UnofficialJuliaMirror,true
UnofficialJuliaMirrorSnapshots,true
UofTActuarial,true
VirtualPlantLab,true
VoxelPopuliEngine,true
WIAS-PDELib,true
WISPO-POP,true
WaterLily-jl,true
WaterWavesModels,true
WaveProp,true
WebSky-CITA,true
WilhelmusLab,true
WiredBrains-Lab,true
XQP-Munich,true
ZIB-IOL,true
ac-tuwien,true
aced-differentiate,true
acfr,true
aclai-lab,true
aenarete,true
agate-model,true
ai4energy,true
aicenter,true
ait-energy,true
akamai,true
alan-turing-institute,true
algebraic-solving,true
amazon-braket,true
analytech-solutions,true
analyticsinmotion,true
anthofflab,true
anyascii,true
anyonlabs,true
apache,true
aramanlab,true
arviz-devs,true
atoptima,true
awesome-spectral-indices,true
awi-esc,true
aws-cqc,true
bancaditalia,true
bankofcanada,true
banyan-team,true
bat,true
bbopt,true
bcbi,true
bcc-research,true
bcube-project,true
beacon-biosignals,true
bhftbootcamp,true
biaslab,true
bibgr,true
bifurcationkit,true
bioinfologics,true
biomass-dev,true
bionanoimaging,true
bmad-sim,true
boydorr,true
brainflow-dev,true
brown-ccv,true
bsc-quantic,true
byu-cxi,true
byuflowlab,true
cadCAD-org,true
cardo-org,true
cclib,true
cesaraustralia,true
cesmix-mit,true
chalk-lab,true
charles-river-analytics,true
chemfiles,true
circstat,true
cite-architecture,true
cloud-oak,true
clugen,true
codedthinking,true
comonicon,true
compbiocore,true
compintell,true
complexphoton,true
complexvariables,true
computationalprivacy,true
comrob,true
control-toolbox,true
corail-research,true
coudertlab,true
cpsylab,true
cropbox,true
csynbiosysIBioEUoE,true
cvdlab,true
cvxgrp,true
cvxopt,true
d2cml-ai,true
dandeliondeathray,true
depasquale-lab,true
dev-ket,true
digitaldomain,true
dionysos-dev,true
dmlc,true
docopt,true
dojo-sim,true
ds4dm,true
dsb-lab,true
dss-extensions,true
duckdb,true
e2nIEE,true
e4st-dev,true
eWaterCycle,true
econetoolbox,true
ediparquantum,true
efpl-columbia,true
eisenforschung,true
emit-sds,true
emsig,true
epfl-matmat,true
eth-cscs,true
eumetsat,true
euro-hpc-pl,true
euroargodev,true
exanauts,true
exercism,true
facultyai,true
fatimp,true
fdcl-nrf,true
fico-xpress,true
fides-dev,true
finch-tensor,true
fkfest,true
flatironinstitute,true
fmrilab,true
fncbook,true
foldfelis-QO,true
forsyde,true
frame-consulting,true
frictionlessdata,true
fugro-oss,true
gamma-opt,true
gdcc,true
geophystech,true
gher-uliege,true
gismo,true
google,true
gridap,true
harmoniqs,true
hetalang,true
hildebrandtlab,true
hiscocklab,true
hlrs-tasc,true
homalg-project,true
homermultitext,true
hpsc-lab,true
idiap,true
iitis,true
impICNF,true
infiniteopt,true
insightsengineering,true
insysbio,true
invenia,true
isrlab,true
jcharistech,true
jl-pkgs,true
jolin-io,true
julia-actions,true
julia-mpsge,true
julia-vscode,true
juliachem-jl,true
juliamatlab,true
jump-dev,true
kahypar,true
ksumngs,true
kul-optec,true
lab-cosmo,true
lambda-mechanics,true
lanl-ansi,true
lazyLibraries,true
leaflabs,true
lescailab,true
libAtoms,true
libplctag,true
libprima,true
lincbrain,true
m3g,true
macroenergy,true
madsjulia,true
manaakiwhenua,true
mathopt,true
matrixfunctions,true
matsunagalab,true
mechanomy,true
medyan-dev,true
menchelab,true
meringlab,true
mggg,true
mi3nts,true
microscopic-image-analysis,true
microsoft,true
mimiframework,true
mind-co,true
ml-unito,true
mlcolab,true
mlpack,true
mpimd-csc,true
nebneuron,true
nep-pack,true
neurallayer,true
nexteraanalytics,true
nflverse,true
nih-niddk-mbs,true
nla-group,true
ntnu-ai-lab,true
nucypher,true
numericalEFT,true
oolong-dev,true
open-AIMS,true
open-and-sustainable,true
opencobra,true
openmodels,true
openpharma,true
org-arl,true
oscar-system,true
osqp,true
oxfordcontrol,true
pasqal-io,true
paveloom-j,true
pc2,true
pgvector,true
pinheiroGroup,true
plasmo-dev,true
plotly,true
portugueslab,true
powsybl,true
pph-collective,true
precice,true
probcomp,true
probsys,true
psace-uofa,true
psrenergy,true
pygae,true
qojulia,true
quadraturerules,true
quantling,true
quantum-exeter,true
quarto-dev,true
queryverse,true
qutip,true
raddleverse,true
railtoolkit,true
rakutentech,true
ralna,true
reseau-constellation,true
rffscghg,true
rigetti,true
rikenbit,true
rodin-physics,true
runtosolve,true
rydyb,true
s-ccs,true
sahu-lab,true
sandialabs,true
santiago-sanitation-systems,true
sciflydev,true
scipopt,true
scverse,true
senresearch,true
sensl,true
seung-lab,true
shahcompbio,true
shareloqs,true
simonsobs,true
sintefmath,true
sintefore,true
sisl,true
slimgroup,true
solislemuslab,true
spine-tools,true
sqids,true
srlearn,true
stochastics-uni-luebeck,true
subnero1,true
suinleelab,true
symengine,true
synchronoustechnologies,true
sys-bio,true
takum-arithmetic,true
tanaylab,true
tensor4all,true
terion-io,true
termolivre,true
thexxiv,true
triscale-innov,true
trishullab,true
trixi-framework,true
tudo-physik-e4,true
tulane-quantum-matter,true
tuwien-cms,true
ubccr-slurm-simulator,true
ucla-epss-djames,true
una-auxme,true
unfoldtoolbox,true
upb-lea,true
usnistgov,true
utahplt,true
uw-windc,true
vanOosterhoutLab,true
velexi-research,true
vidriotech,true
waudbygroup,true
weecology,true
wexlergroup,true
worlddynamics,true
xKDR,true
xtensor-stack,true
yaml,true
zavalab,true
zemjulia,true
zobainc,true
"""