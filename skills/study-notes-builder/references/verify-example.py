"""Independent recomputation of every Part II worked example.
Run: python3 part2.py   — prints tables the notes must match."""
import math

def sign0(x, theta=0.0):
    if x > theta: return 1
    if x < -theta: return -1
    return 0

# ---------------------------------------------------------------------------
print("="*70); print("PERCEPTRON — AND gate, bipolar, alpha=1, theta=0, w0=b=0")
print("="*70)
data = [((1,1),1),((1,-1),-1),((-1,1),-1),((-1,-1),-1)]
w=[0.0,0.0]; b=0.0; a=1.0
for epoch in range(1,4):
    changed=False
    print(f"-- epoch {epoch}")
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        y=sign0(yin,0)
        upd = (y!=t)
        if upd:
            w=[wi+a*t*xi for wi,xi in zip(w,x)]; b=b+a*t; changed=True
        print(f"  x={x} t={t:+d} yin={yin:+.1f} y={y:+d} {'UPDATE' if upd else '-'} -> w={w} b={b}")
    if not changed:
        print(f"  converged after epoch {epoch}"); break
print("FINAL perceptron AND:", w, b, " boundary: %g x1 + %g x2 + %g = 0"%(w[0],w[1],b))

# ---------------------------------------------------------------------------
print("="*70); print("PERCEPTRON — OR, binary inputs, bipolar targets, alpha=1, theta=0.2")
print("="*70)
data=[((1,1),1),((1,0),1),((0,1),1),((0,0),-1)]
w=[0.0,0.0]; b=0.0; a=1.0; th=0.2
for epoch in range(1,6):
    changed=False
    print(f"-- epoch {epoch}")
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        y=sign0(yin,th)
        upd=(y!=t)
        if upd:
            w=[wi+a*t*xi for wi,xi in zip(w,x)]; b=b+a*t; changed=True
        print(f"  x={x} t={t:+d} yin={yin:+.2f} y={y:+d} {'UPD' if upd else '-'} -> w={w} b={b}")
    if not changed:
        print(f"  converged after epoch {epoch}"); break
print("FINAL perceptron OR:", w, b)

# ---------------------------------------------------------------------------
print("="*70); print("PERCEPTRON — ANDNOT (x1 and not x2), bipolar, alpha=1, theta=0")
print("="*70)
data=[((1,1),-1),((1,-1),1),((-1,1),-1),((-1,-1),-1)]
w=[0.0,0.0]; b=0.0; a=1.0
for epoch in range(1,8):
    changed=False
    print(f"-- epoch {epoch}")
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        y=sign0(yin,0)
        upd=(y!=t)
        if upd:
            w=[wi+a*t*xi for wi,xi in zip(w,x)]; b=b+a*t; changed=True
        print(f"  x={x} t={t:+d} yin={yin:+.1f} y={y:+d} {'UPD' if upd else '-'} -> w={w} b={b}")
    if not changed:
        print(f"  converged after epoch {epoch}"); break
print("FINAL perceptron ANDNOT:", w, b)

# ---------------------------------------------------------------------------
print("="*70); print("PERCEPTRON — 4-component vectors, alpha=1, theta=0.2")
print("="*70)
data=[((1,1,1,1),1),((-1,1,-1,-1),1),((1,1,1,-1),-1),((1,-1,-1,1),-1)]
w=[0.0]*4; b=0.0; a=1.0; th=0.2
for epoch in range(1,8):
    changed=False
    print(f"-- epoch {epoch}")
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        y=sign0(yin,th)
        upd=(y!=t)
        if upd:
            w=[wi+a*t*xi for wi,xi in zip(w,x)]; b=b+a*t; changed=True
        print(f"  x={x} t={t:+d} yin={yin:+.2f} y={y:+d} {'UPD' if upd else '-'} -> w={w} b={b:+.1f}")
    if not changed:
        print(f"  converged after epoch {epoch}"); break
print("FINAL 4-comp:", w, b)

# ---------------------------------------------------------------------------
print("="*70); print("ADALINE — OR bipolar, w=b=0.1, alpha=0.1  (MSE per epoch)")
print("="*70)
data=[((1,1),1),((1,-1),1),((-1,1),1),((-1,-1),-1)]
w=[0.1,0.1]; b=0.1; a=0.1
for epoch in range(1,7):
    se=0.0
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        e=t-yin
        w=[wi+a*e*xi for wi,xi in zip(w,x)]; b=b+a*e
        se+=e*e
    print(f"  epoch {epoch}: SSE={se:.4f}  w={[round(v,4) for v in w]} b={b:.4f}")
print("ADALINE OR final:", [round(v,4) for v in w], round(b,4))

# ---------------------------------------------------------------------------
print("="*70); print("ADALINE — ANDNOT bipolar, w=b=0.2, alpha=0.2  (MSE per epoch)")
print("="*70)
data=[((1,1),-1),((1,-1),1),((-1,1),-1),((-1,-1),-1)]
w=[0.2,0.2]; b=0.2; a=0.2
for epoch in range(1,7):
    se=0.0
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        e=t-yin
        w=[wi+a*e*xi for wi,xi in zip(w,x)]; b=b+a*e
        se+=e*e
    print(f"  epoch {epoch}: SSE={se:.4f}  w={[round(v,4) for v in w]} b={b:.4f}")

# ---------------------------------------------------------------------------
print("="*70); print("ADALINE — AND bipolar, w=b=0.2, alpha=0.2  (extra)")
print("="*70)
data=[((1,1),1),((1,-1),-1),((-1,1),-1),((-1,-1),-1)]
w=[0.2,0.2]; b=0.2; a=0.2
for epoch in range(1,7):
    se=0.0
    for (x,t) in data:
        yin=b+sum(wi*xi for wi,xi in zip(w,x))
        e=t-yin
        w=[wi+a*e*xi for wi,xi in zip(w,x)]; b=b+a*e
        se+=e*e
    print(f"  epoch {epoch}: SSE={se:.4f}  w={[round(v,4) for v in w]} b={b:.4f}")

# ---------------------------------------------------------------------------
print("="*70); print("MADALINE — XOR, alpha=0.5, MRI. Initial weights from S&D fig")
print("="*70)
# hidden: z1: w11=0.05 w21=0.2 b1=0.3 ; z2: w12=0.1 w22=0.2 b2=0.15
# output fixed: v1=v2=0.5 b0=0.5
def f(x): return 1 if x>=0 else -1
W=[[0.05,0.2],[0.1,0.2]]  # W[j] = [w1j, w2j]
bh=[0.3,0.15]
v=[0.5,0.5]; b0=0.5; a=0.5
data=[((1,1),-1),((1,-1),1),((-1,1),1),((-1,-1),-1)]
def madaline_pass(data,W,bh,verbose=True):
    for (x,t) in data:
        zin=[bh[j]+W[j][0]*x[0]+W[j][1]*x[1] for j in range(2)]
        z=[f(zi) for zi in zin]
        yin=b0+v[0]*z[0]+v[1]*z[1]
        y=f(yin)
        line=f"  x={x} t={t:+d} zin={[round(q,3) for q in zin]} z={z} yin={yin:+.3f} y={y:+d}"
        if y!=t:
            if t==1:
                # update the hidden unit whose zin is closest to 0
                j=min(range(2), key=lambda k: abs(zin[k]))
                bh[j]=bh[j]+a*(1-zin[j])
                W[j]=[W[j][0]+a*(1-zin[j])*x[0], W[j][1]+a*(1-zin[j])*x[1]]
                line+=f"  -> update z{j+1}"
            else:
                for k in range(2):
                    if zin[k]>0:
                        bh[k]=bh[k]+a*(-1-zin[k])
                        W[k]=[W[k][0]+a*(-1-zin[k])*x[0], W[k][1]+a*(-1-zin[k])*x[1]]
                line+="  -> update all z with zin>0"
        else:
            line+="  -> no update"
        if verbose: print(line)
    return W,bh
print("-- pass 1")
W,bh=madaline_pass(data,W,bh)
print("after pass 1: W=",[[round(q,4) for q in r] for r in W]," bh=",[round(q,4) for q in bh])

# ---------------------------------------------------------------------------
print("="*70); print("BPN problem 1 — binary sigmoid, x=[0,1], t=1, alpha=0.25")
print("="*70)
def bsig(x): return 1/(1+math.exp(-x))
v0=[0.3,0.5]; v=[[0.6,-0.3],[-0.1,0.4]]  # v[i][j]: input i -> hidden j
w0=-0.2; w=[0.4,0.1]
x=[0,1]; t=1; a=0.25
zin=[v0[j]+sum(x[i]*v[i][j] for i in range(2)) for j in range(2)]
z=[bsig(q) for q in zin]
yin=w0+sum(z[j]*w[j] for j in range(2))
y=bsig(yin)
dk=(t-y)*y*(1-y)
dw=[a*dk*z[j] for j in range(2)]; dw0=a*dk
din=[dk*w[j] for j in range(2)]
dj=[din[j]*z[j]*(1-z[j]) for j in range(2)]
dv=[[a*dj[j]*x[i] for j in range(2)] for i in range(2)]
dv0=[a*dj[j] for j in range(2)]
print(f"zin={[round(q,4) for q in zin]}  z={[round(q,4) for q in z]}")
print(f"yin={yin:.5f}  y={y:.4f}")
print(f"delta_k={dk:.4f}")
print(f"dw1={dw[0]:.5f} dw2={dw[1]:.5f} dw0={dw0:.5f}")
print(f"delta_in=[{din[0]:.5f},{din[1]:.5f}]  delta_j=[{dj[0]:.5f},{dj[1]:.5f}]")
print(f"dv11={dv[0][0]:.5f} dv21={dv[1][0]:.5f} dv12={dv[0][1]:.5f} dv22={dv[1][1]:.5f}")
print(f"dv01={dv0[0]:.5f} dv02={dv0[1]:.5f}")
wn=[w[j]+dw[j] for j in range(2)]; w0n=w0+dw0
vn=[[v[i][j]+dv[i][j] for j in range(2)] for i in range(2)]
v0n=[v0[j]+dv0[j] for j in range(2)]
print("NEW w:",[round(q,5) for q in wn]," w0:",round(w0n,5))
print("NEW v:",[[round(q,5) for q in r] for r in vn]," v0:",[round(q,5) for q in v0n])

# ---------------------------------------------------------------------------
print("="*70); print("BPN problem 2 — bipolar sigmoid, x=[-1,1], t=1, alpha=0.25")
print("="*70)
def psig(x): return 2/(1+math.exp(-x))-1
def psig_d(fx): return 0.5*(1+fx)*(1-fx)
v0=[0.3,0.5]; v=[[0.6,-0.3],[-0.1,0.4]]
w0=-0.2; w=[0.4,0.1]
x=[-1,1]; t=1; a=0.25
zin=[v0[j]+sum(x[i]*v[i][j] for i in range(2)) for j in range(2)]
z=[psig(q) for q in zin]
yin=w0+sum(z[j]*w[j] for j in range(2))
y=psig(yin)
dk=(t-y)*psig_d(y)
dw=[a*dk*z[j] for j in range(2)]; dw0=a*dk
din=[dk*w[j] for j in range(2)]
dj=[din[j]*psig_d(z[j]) for j in range(2)]
dv=[[a*dj[j]*x[i] for j in range(2)] for i in range(2)]
dv0=[a*dj[j] for j in range(2)]
print(f"zin={[round(q,4) for q in zin]}  z={[round(q,4) for q in z]}")
print(f"yin={yin:.5f}  y={y:.4f}")
print(f"delta_k={dk:.4f}")
print(f"dw1={dw[0]:.5f} dw2={dw[1]:.5f} dw0={dw0:.5f}")
print(f"delta_in=[{din[0]:.5f},{din[1]:.5f}]  delta_j=[{dj[0]:.5f},{dj[1]:.5f}]")
wn=[w[j]+dw[j] for j in range(2)]; w0n=w0+dw0
vn=[[v[i][j]+dv[i][j] for j in range(2)] for i in range(2)]
v0n=[v0[j]+dv0[j] for j in range(2)]
print("NEW w:",[round(q,5) for q in wn]," w0:",round(w0n,5))
print("NEW v:",[[round(q,5) for q in r] for r in vn]," v0:",[round(q,5) for q in v0n])
