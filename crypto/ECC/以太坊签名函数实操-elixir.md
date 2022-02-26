# 以太坊签名函数实操

> 函数式编程是有别于传统的面对对象范式的编程范式，函数式方向是目前编程语言发展的大方向，所有新设计的编程语言都或多或少的引入了函数式编程功能。
>
> 笔者认为，「下一代计算机学科体系」将基于函数式编程语言。因此，打好函数式编程基础对于具备「长期主义」思维的程序员是必要的。

**关于本专栏：**

> 本专栏将通过实战代码分析与经典著作解读，分享作者关于函数式编程与区块链的思考与实践。就目前而言，本专栏将基于两种函数式语言：**Rust 和 Elixir**，有时候会提及其它语言，作为辅助性参考。

前文索引：

> [理解以太坊合约数据读取过程 | 函数式与区块链（二）](http://mp.weixin.qq.com/s?__biz=MzI0NTM0MzE5Mw==&mid=2247485420&idx=1&sn=1149067c6a0bfb13bde552bb5721eefd&chksm=e94eb15ade39384c9e68e2bd6bf321640b5da57eefc828ff92b24669fe6e4aa93468464f74e3&scene=21#wechat_redirect)
>
> [太上中的基因设计与 Binary | 函数式与区块链（一）](http://mp.weixin.qq.com/s?__biz=MzI0NTM0MzE5Mw==&mid=2247485413&idx=1&sn=80b72e45f31d71ab0e564004f5a5fb06&chksm=e94eb153de3938451126266b8bc2213f34ebf7af35993b2f1c93666e5cde9512ea97397331c5&scene=21#wechat_redirect)

本篇描述 Elixir 与 Rust 两种函数式编程语言下 ECDSA 算法下使用 Secp256k1 签名的过程。

本文侧重相关库的使用，相关原理解析可见：

> 一个数字引发的探索——ECDSA 解析：
>
> https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/articles/3_features/36_cryptographic/ecdsa_analysis.html?highlight=v%20r%20s
>
> 一场椭圆曲线的寻根问祖之旅：
>
> https://fisco-bcos-documentation.readthedocs.io/zh_CN/dev/docs/articles/3_features/36_cryptographic/elliptic_curve.html

在 Elixir 中，使用了 `libsecp256k1`库：

```elixir
# mix.exs
 defp deps do
    [
    	...
    	{:libsecp256k1, "~> 0.1.9"},
    	...
    ]
```

完整的实现被最终打包在：

> https://github.com/leeduckgo/eth_wallet

并可以通过 mix 进行导入：

```
{:eth_wallet, ">= 0.0.12"}
```

在 Rust 中，使用了`secp256k1`库与`bitcoin_hashes`库：

```rust
# cargo.toml
[dependencies]
secp256k1 = {version = "0.20.3", features = ["rand-std", "recovery"] }
bitcoin_hashes = "0.9"
```

完整实现见：

> https://github.com/leeduckgo/secp256k1-example-rs

## 未压缩的签名

未压缩的签名即是简单粗暴的直接用私钥（privkey）给信息（message）进行签名，签名字节数可能是 71、72 或 73。

### Elixir 中的实现

在 elixir 中的签名和验签通过`:crypto`这个库实现。

```elixir
# https://github.com/leeduckgo/eth_wallet/blob/main/lib/utils/crypto.ex
def sign(digest, priv) do
  {:ok, res} = :libsecp256k1.ecdsa_sign(digest, priv, :default, <<>>)
  res
end

def verify(digest, sig, pubkey) do
  # :crypto.verify(:ecdsa, :sha256, msg, sig, [pubkey, :secp256k1])
  case :libsecp256k1.ecdsa_verify(digest, sig, pubkey) do
    :ok -> true
    _ -> false
  end
end
```

### Rust 中的实现

```rust
///https://github.com/leeduckgo/secp256k1-example-rs/blob/main/src/main.rs

fn main(){
    let (seckey, pubkey) = generate_keys();
    let digest = b"This is some message";
    let sig = sign(digest, seckey);
    let serialize_sig = sig.serialize_compact().to_vec();
    verify(digest, serialize_sig, pubkey);
}

///https://github.com/rust-bitcoin/rust-secp256k1/blob/master/examples/sign_verify.rs
fn sign(digest: &[u8], seckey: SecretKey) -> Signature {
    let secp = Secp256k1::new();
    let signature = do_sign(&secp, digest, seckey).unwrap();
    println!("signature: {:?}", signature);
    signature
}

fn verify(digest: &[u8], sig: Vec<u8>, pubkey: PublicKey){
    let secp = Secp256k1::new();
    let result = do_verify(&secp, digest, sig, pubkey).unwrap();
    println!("verify result: {:?}", result)
}

fn do_sign<C: Signing>(secp: &Secp256k1<C>, digest: &[u8], seckey: SecretKey) -> Result<Signature, Error> {
    let digest = sha256::Hash::hash(digest);
    let digest = Message::from_slice(&digest)?;
    Ok(secp.sign(&digest, &seckey))
}

fn do_verify<C: Verification>(secp: &Secp256k1<C>, digest: &[u8], sig: Vec<u8>, pubkey: PublicKey) -> Result<bool, Error> {
    let digest = sha256::Hash::hash(digest);
    let digest = Message::from_slice(&digest)?;
    let sig = Signature::from_compact(&sig)?;

    Ok(secp.verify(&digest, &sig, &pubkey).is_ok())
}
```

## 压缩的签名

通过压缩签名算法（sign_compact），会生成 v, r, s。r 和 s 拼凑起来是签名本体，v 的全称是 Recovery ID，起到从签名中恢复公钥的作用。

> 对比比特币签名，以太坊的签名格式是`r+s+v`。 r 和 s 是 ECDSA 签名的原始输出，而末尾的一个字节为 recovery id 值，但在以太坊中用`V`表示，v 值为 1 或者 0。recovery id 简称 recid，表示从内容和签名中成功恢复出公钥时需要查找的次数（因为根据`r`值在椭圆曲线中查找符合要求的坐标点可能有多个），但在比特币下最多需要查找两次。这样在签名校验恢复公钥时，不需要遍历查找，一次便可找准公钥，加速签名校验速度。
>
> —— https://learnblockchain.cn/books/geth/part3/sign-and-valid.html

压缩签名的长度是 r 和 s 各是 32 字节，v 是 1 字节，总共是 65 字节。

### Elixir 中的实现

压缩签名函数实现：

```elixir
@base_recovery_id 27
@base_recovery_id_eip_155 35

@doc """
  The test is here:

  https://github.com/exthereum/exth_crypto/blob/master/lib/signature/signature.ex

  Attention: hash should be 32 bytes.
"""
def sign_compact(digest, privkey, chain_id \\ nil) do
  # {:libsecp256k1, "~> 0.1.9"} is useful.
  {:ok, <<r::size(256), s::size(256)>> = sig, recovery_id} =
    :libsecp256k1.ecdsa_sign_compact(digest, privkey, :default, <<>>)

  recovery_id_handled =
    recovery_id_to_recovery_id_handled(recovery_id, chain_id)

  %{v: recovery_id_handled, r: r, s: s, sig: sig}
end


defp recovery_id_to_recovery_id_handled(recovery_id, chain_id) do
  if chain_id do
    chain_id * 2 + @base_recovery_id_eip_155 + recovery_id
  else
    @base_recovery_id + recovery_id
  end
end
```

公钥恢复函数：

```elixir
def recover(digest, signature, recovery_id_handled , chain_id \\ nil) do
  recovery_id =
    recovery_id_handled_to_recovery_id(recovery_id_handled, chain_id)
  case :libsecp256k1.ecdsa_recover_compact(digest, signature, :uncompressed, recovery_id) do
    {:ok, public_key} -> {:ok, public_key}
    {:error, reason} -> {:error, to_string(reason)}
  end
end

defp recovery_id_handled_to_recovery_id(recovery_id_handled, chain_id) do
  if chain_id do
    recovery_id_handled - chain_id * 2 - @base_recovery_id_eip_155
  else
    recovery_id_handled - @base_recovery_id
  end
end
```

### Rust 中的实现

压缩签名函数实现：

```rust
fn sign_compact(digest: &[u8], seckey: SecretKey) -> (RecoveryId, Vec<u8>) {
    let secp = Secp256k1::new();
    let signature = do_sign_compact(&secp, digest, seckey).unwrap();
    let (recovery_id, serialized_sig) = signature.serialize_compact();
    println!("signature compacted: {:?}", serialized_sig);
    println!("recovery id: {:?}", recovery_id);
    (recovery_id, serialized_sig.to_vec())
}

fn do_sign_compact<C: Signing>(secp: &Secp256k1<C>, digest: &[u8], seckey: SecretKey) -> Result<RecoverableSignature, Error> {
    let digest = sha256::Hash::hash(digest);
    let digest = Message::from_slice(&digest)?;
    Ok(secp.sign_recoverable(&digest, &seckey))
}
```

公钥恢复函数：

```rust
fn recover(digest: &[u8],sig: Vec<u8>,recovery_id: RecoveryId) {
    let secp = Secp256k1::new();
    let pubkey = do_recover(&secp, digest, sig, recovery_id);
    println!("pubkey recovered: {:?}", pubkey)
}
fn do_recover<C: Verification>(secp: &Secp256k1<C>,digest: &[u8],sig: Vec<u8>,recovery_id: RecoveryId) -> Result<PublicKey, Error> {
    let digest = sha256::Hash::hash(digest);
    let digest = Message::from_slice(&digest)?;
    let sig = RecoverableSignature::from_compact(&sig, recovery_id)?;

    secp.recover(&digest, &sig)
}
```

完整主函数（main）：

```rust
fn main(){
    let (seckey, pubkey) = generate_keys();
    let digest = b"This is some message";
    let sig = sign(digest, seckey);
    let serialize_sig = sig.serialize_compact().to_vec();
    verify(digest, serialize_sig, pubkey);
    let (recovery_id, sig_compact) = sign_compact(digest, seckey);
    verify(digest, sig_compact.clone(), pubkey);
    recover(digest, sig_compact, recovery_id);
}
```
