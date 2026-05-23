package com.example.demo.utils;

import java.io.IOException;
import java.io.InputStream;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.example.demo.exception.AuthException;

import cn.hutool.core.codec.Base64;
import cn.hutool.core.io.resource.Resource;
import cn.hutool.core.io.resource.ResourceUtil;
import cn.hutool.crypto.PemUtil;
import cn.hutool.crypto.asymmetric.KeyType;
import cn.hutool.crypto.asymmetric.RSA;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class RsaUtil {

    @Value("${key-path}")
    private String path;
    private RSA rsa;

    @PostConstruct
    void init() {
        try {
            Resource privateKey = ResourceUtil.getResourceObj(path + "/private.pem");
            Resource publicKey = ResourceUtil.getResourceObj(path + "/public.pem");
            try (InputStream in1 = privateKey.getStream(); InputStream in2 = publicKey.getStream();) {
                rsa = new RSA(PemUtil.readPemPrivateKey(in1), PemUtil.readPemPublicKey(in2));
            }
            log.info("Finish the initialization of RSA");
        } catch (Exception e) {
            log.warn("RSA密钥文件未找到，RSA功能不可用（测试模式可忽略），路径：{}", path);
        }
    }

    private void checkRsaInitialized() {
        if (rsa == null) {
            throw new IllegalStateException("RSA加密工具类未初始化成功，无法执行加密/解密操作，请检查密钥配置");
        }
    }

    public String decrypt(String code) {
        checkRsaInitialized();
        String password;
        try {
            password = rsa.decryptStr(code, KeyType.PrivateKey);
        } catch (RuntimeException _) {
            throw new AuthException(AuthException.Type.PASSWORD_ERROR, "无效的密文");
        }
        return password;
    }

    public String encrypt(String code) {
        checkRsaInitialized();
        return rsa.encryptBase64(code, KeyType.PublicKey);
    }

    public String getPublicKey() {
        checkRsaInitialized();
        return Base64.encode(rsa.getPublicKey().getEncoded());
    }
}