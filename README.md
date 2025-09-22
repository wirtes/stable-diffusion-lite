# Dockerized Stable Diffusion API

A flexible Stable Diffusion API with both CPU and GPU support, designed to work efficiently on any sy

## Features

- **Dual deployment options**: CPU-only or GPU-accelerated
- **Auto-device detection**: Automaticale
- **Optimized performance**: Device-specifd
- **RESTful API** with simplee
- **Docker containerizement
- **Health check endpion
n
- **Reproducib
ing

arison

| Mode | Generation Time | Iments |
|------|----------------|-|

| **GPU** | 5-15 seconds | Excellent | 4-6GB VRAM | DA |

tart

are:

### 🖥️ CPU-Only m)

 only:

```bash
# Bversion


8080
```

### 🚀 quired)

For:

**Prerequisites:**
port
- [NVIDIA Container Toolkit](https://dlled
- Dockeort

```bash
# Buildn
docker compose -f docker-compose.gpu.yml up --build

# T080


### 🐳 mmands

**CPU Version:**
```bash
docker build -f Dockerfile.cpu -t stable-diffusion-api-cpu .
docker run -p 80
```

**GPU Version:**
```bash
docker build -f Dockerfile.gpu -t stable-diffusion-api-gpu .
doc


## API sage

### Health Check

Check API status and device infotion:

```bash
curl http://localhealth
```


```json

  "status": "healthy",
pu",
  "mode
}
```

**GPU Respons
```json
{
  "status": "healthy",
  "device": "cuda",
true,
  "gpu_name": "NVIDIA GeForce RTX 4090",
  "gpu_memory_gb": 24.0
}
``

### Generate Image

Basic example (save response to file):
```bash
curl -X POST http://localhost:8080/generae \
n" \
  -d '{
s"
  }' > responn
```

Generate withrs:
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a detailed portrait of a cat wearing a hat",
    "steps": 30,
    "width": 512,
    "height": 512,
    "guidance_scale": 8.0,
    "seed": 12345
  }' | jq -r '.image' | sed 's/data:image\/png;base64,//' | base64
```

Alternative without jq (using grep and s):
ash
curl -X POST htt
" \
  -d '{
",
    "st0,
 ,
    "height": 256
  }' | grep -o '"image":"[^"]*"' | sed 's/"image":"//g' | sed 'ng
```

### Saving Images with H

The included `save_iU modes:

```bash
table
chmod +x save_image.h

# Basic usage
./save_image.sh "a cute robot"

# With custom filename
./save_image.sh "a cute robot" my_robot.png

size)
./save_image.sh "a su 512


The scry:
-
- Shows generation progress and timing
- Extracts and
- Provides erro
- Works withoutn

## rs

**Required:**
- `promte

**Optional:**
- `steps` (inteps
  - **CPU defau)
  - **GPU defaulity)
- `guidance_scale` (flot
 mpt
  -
mpt
- `width` (integer, default: 512els
  - **Cefficiency
 ity
- `height` (integer, default: 512): Imag)
- `seed` (intelts
  - If not provly
  - Range: 0 to  - 1)

#

:

```json
{
  "success": true,
  "image": "d",
  "prompt": "
 ": 30,
  ": 7.5,

  "seed": 1847392847,
  "devi
}
```

**Response Fiel
-
- `x

- `steps` (integer): Numbeps used
- `guid
-at
- `seed` (integer): The seed value ubility)
- `device` (str")

#alls

:**
```json

  "prompt": "a simple cat drawing",

  "width": 256,
  "height": 256
}
```

**Balanced quality:**
```json
{
  "prompt": "a detailed landscape painting",

  "width":,
12,
  "guidance_scale": 7.5

```

**H**
son
{
,
  "steps": 50,

  "height": 768,
  "guidance_scale": 8.0
}
```

**Reproducible generation (with seed):**
```json

  "prompt": "a magical f",
 42,
  "steps": 30
}
```

## Seed Functionality

The `seed` parameter con

- **Random generation**:ime
- **Reproducible results**: Usges

- **Sharing**: Shart results

**Example workflow:**

2. Note the seed value ree
3. Use that seed with modified promns
tingthe included test script (works with both modes): use.cial commernse beforel licemodeiew the evlease r terms. P own licensehich has its model wv1.5sion e DiffuStable  uses thprojectThis  License


##ld`
p --bui|gpu].yml upu.[cmposecker-co dor compose -fckeUse `dobuild**: 4. **Rese file
ocker-compole and dve Dockerfihe respecti Update toth**:. **For b
3ts-gpu.txt`quiremen` and `re`app-gpu.pyes**: Edit  chang. **For GPU.txt`
2punts-cme `require.py` andp-cpuap**: Edit `anges*For CPU chon:

1. * applicatithey 

To modifmentDevelop## y)
```

callautomatied y (creattorache direcModel c     #            he/     
└── cac script test      # API         .py pi test_aimages
├──ving sapt for  Helper scri        #.sh      mage_isavees
├── U dependenci    # GP-gpu.txt    ntsme├── requireencies
 depend # CPU   txt    s-cpu.entuirem req├──n
d applicatiomizeU-opti       # GPy           pu.p── app-g
├tionplicad aptimizeop CPU-          #        pp-cpu.py aimage
├──ocker  D GPU    #          e.gpu Dockerfilr image
├── # CPU Docke       pu      kerfile.c
├── Docent deploymGPUml       # pose.gpu.yocker-com
├── dtdeploymen   # CPU cpu.yml    ker-compose.docfile
├──  This       #         DME.md     `
├── REAucture

`` Str File

##ew portls to use n calPI A
- Update0 is in use if 808ese filos-comp dockerange port in Chts:**
-flicon**Port C

rf ./cache`: `rm -corruptedar cache if Cleory
- direct` n `./cached ite persisache ismodel c
- The tionrnet connece intebl sta
- Ensureues:**ownload IssModel D

**al Issuesener
### Gsion
U driver verCheck GPge
-  Docker imalding thery rebuiibility
- Tn compatrsio veDA Ensure CU
-* Errors:*s

**CUDAcationpli ape other GPU)
- Closiedif modifsize (uce batch ednsions
- Rmeuce image di
- Red*AM:*t of VR`

**Oue nvidia-smia:11.8-basnvidia/cudall --gpus  --rm r runess: `dockehas GPU accer re Dock
- Ensustemon host sy works `nvidia-smi`k 
- Checnstalleds iolkit iner ToontaiIDIA Cy NV- Verifected:**
GPU Not Det**e Issues

PU Mod

### Gnnings are ruavy processeno other he
- Ensure ps to 10-15cing steeduer rsid- conCPU on pected ex This is ion:**
-ow Generat

**Slimitr memory lrease Docke
- Inc stepsce inferencedu256)
- Re, 256xnsions (e.g.image dimece *
- Redurrors:*Memory Et of 

**OusMode Issue# CPU oting

##roublesho1.8+

## Tith CUDA 1tible wDA**: CompaCU
- **mageonds per i-15 sec 5 time**:eneration **Gendencies
-and depB for model : ~6Gorage**- **Stsystem RAM
 4GB AM**:nded)
- **RGB+ recommeAM (64GB+ VRith PU w NVIDIA GPU**:de
- **GPU Moage

### Gs per imnute*: 2-5 miation time*- **Generndencies
 depeandB for model **: ~6G **Storagees
-PU cor, 4 C 8GB RAMended**:**Recomm
-  coresRAM, 2 CPU: 4GB imum**ode
- **MinU M

### CPntsemeource Requir
## Resading
nlo-dowreoid lly to avhed locals are cac*: ModeCache*
- **(GPU)768x768 r up to x512 (CPU) oized for 512tim*: Option* **Resoluad
-wnlo ~4GB do **Size**:n-v1-5`
-sioe-diffublwayml/staodel**: `run

- **MInformation
## Model g`.
ed_image.pnat as `generest image, saving a tonneratie gemagnd iendpoint aealth oth the h test b willhis

Tapi.py
```hon test_sh
pyt```ba



Run 
## Tes