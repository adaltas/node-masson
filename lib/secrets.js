
var Store;

import fs from 'fs/promises';

import fsOrg from 'fs';

import crypto from 'crypto';

import yaml from 'js-yaml';

import generator from 'generate-password';

import get from 'lodash.get';

import set from 'lodash.set';

import unset from 'lodash.unset';

Store = class Store {
  constructor(options1 = {}) {
    var base, base1, base2, base3;
    this.options = options1;
    if ((base = this.options).store == null) {
      base.store = '.secrets';
    }
    if ((base1 = this.options).envpw == null) {
      base1.envpw = 'MASSON_SECRET_PW';
    }
    if ((base2 = this.options).password == null) {
      base2.password = process.env[this.options.envpw];
    }
    if ((base3 = this.options).algorithm == null) {
      base3.algorithm = 'aes-256-ctr';
    }
  }

  async unset(key) {
    var secrets;
    secrets = (await this.get());
    unset(secrets, key);
    return (await this.set(secrets));
  }

  async get() {
    var key, secrets;
    if (arguments.length === 1) {
      key = arguments[0];
    } else if (arguments.length !== 0) {
      throw Error(`Invalid get arguments: got ${JSON.stringify(arguments)}`);
    }
    await this._read();
    secrets = this.decrypt(this.raw, this.iv);
    if (key) {
      return get(secrets, key);
    } else {
      return secrets;
    }
  }

  getSync() {
    var key, secrets;
    // ()
    if (arguments.length === 1) {
      key = arguments[0];
    } else if (arguments.length !== 0) {
      throw Error(`Invalid getSync arguments: got ${JSON.stringify(arguments)}`);
    }
    this._readSync();
    secrets = this.decrypt(this.raw, this.iv);
    if (key) {
      return get(secrets, key);
    } else {
      return secrets;
    }
  }

  async set() {
    var data, key, secrets, value;
    // (secrets)
    if (arguments.length === 1) {
      secrets = arguments[0];
      await this._read();
      secrets = this.encrypt(secrets, this.iv);
      this.raw = Buffer.from(secrets);
      data = Buffer.concat([this.iv, this.raw]);
      return (await fs.writeFile(this.options.store, data));
    // (key, value)
    } else if (arguments.length === 2) {
      key = arguments[0];
      value = arguments[1];
      secrets = (await this.get());
      set(secrets, key, value);
      await this.set(secrets);
    } else {
      throw Error(`Invalid set arguments: got ${JSON.stringify(arguments)}`);
    }
  }

  async init() {
    var iv;
    if ((await this.exists())) {
      throw Error('Store already created');
    }
    iv = crypto.randomBytes(16);
    return (await fs.writeFile(this.options.store, iv));
  }

  password(options = {}) {
    return generator.generate(Object.assign({
      length: 10,
      numbers: true
    }, options));
  }

  async _read() {
    var data, err;
    if (this.iv && this.raw) {
      return {
        if: this.iv,
        raw: this.raw
      };
    }
    try {
      await fs.stat(this.options.store);
      data = (await fs.readFile(this.options.store));
      this.iv = data.slice(0, 16);
      this.raw = data.slice(16);
      return {
        if: this.iv,
        raw: this.raw
      };
    } catch (error) {
      err = error;
      if (err.code !== 'ENOENT') {
        throw err;
      }
      throw Error('Secret store not initialized');
    }
  }

  _readSync() {
    var data, err;
    if (this.iv && this.raw) {
      return [this.iv, this.raw];
    }
    try {
      fsOrg.statSync(this.options.store);
    } catch (error) {
      err = error;
      throw Error('Secret store not initialized');
    }
    data = fsOrg.readFileSync(this.options.store);
    this.iv = data.slice(0, 16);
    this.raw = data.slice(16);
    return [this.iv, this.raw];
  }

  // Check if the store is created
  async exists() {
    var err;
    try {
      await fs.stat(this.options.store);
      return true;
    } catch (error) {
      err = error;
      if (err.code !== 'ENOENT') {
        throw err;
      }
      return false;
    }
  }

  // Encrypt some text
  encrypt(secrets, iv) {
    var cipher, crypted, key, text;
    text = JSON.stringify(secrets);
    key = crypto.createHash('sha256').update(this.options.password).digest().slice(0, 32);
    cipher = crypto.createCipheriv(this.options.algorithm, key, iv);
    crypted = cipher.update(text, 'utf8', 'hex');
    crypted += cipher.final('hex');
    return crypted;
  }

  // Decrypt some text
  decrypt(text, iv) {
    var dec, decipher, err, key, secrets;
    try {
      if (Buffer.isBuffer(text)) {
        text = text.toString('utf8');
      }
      key = crypto.createHash('sha256').update(this.options.password).digest().slice(0, 32);
      decipher = crypto.createDecipheriv(this.options.algorithm, key, iv);
      dec = decipher.update(text, 'hex', 'utf8');
      dec += decipher.final('utf8');
      secrets = JSON.parse(dec || '{}');
    } catch (error) {
      err = error;
      console.log("\x1b[31mError when decrypting password store. Is the password set and correct ?\x1b[0m");
      throw err;
    }
    return secrets;
  }

};

export default function(options) {
  return new Store(options);
};
