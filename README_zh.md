# rsdk-image

Debian 12 离线 Docker 镜像包，提供预构建的 Debian 12 容器镜像供离线使用。

## 安装

从 [Releases](https://github.com/xzl01/rsdk-image/releases) 页面下载最新的 `.deb` 包。

安装：

```bash
sudo dpkg -i rsdk-image_*.deb
```

或带依赖安装：

```bash
sudo apt install ./rsdk-image_*.deb
```

## 使用

安装后，可使用 `run-rsdk-image` 命令。

运行容器：

```bash
run-rsdk-image
```

这将启动一个交互式的 Debian 12 容器，最小化挂载（网络配置、时区、home 目录）。提示符会显示 `[rsdk]` 表示你在容器内。

### 在容器内安装 rsdk

进入容器后，可以使用捆绑的脚本安装 rsdk (Radxa SDK)：

```bash
install-rsdk.sh
```

使用国内镜像加速下载：

```bash
install-rsdk.sh -c
```

这将安装 rsdk 包并设置开发环境。

选项：

- `--name NAME`: 设置容器名称
- `--`: 传递额外参数给 `docker run`

示例：

```bash
run-rsdk-image --name my-container -- bash -c "echo hello"
```

## 从源码构建

克隆仓库：

```bash
git clone https://github.com/xzl01/rsdk-image.git
cd rsdk-image
```

构建 Debian 包：

```bash
make deb
```

需要 Docker 和构建依赖。包将在 `../rsdk-image_*.deb`。

## CI/CD

GitHub Actions 在推送到 main 分支时自动构建 amd64 和 arm64 包，并创建发布。

## 许可证

详见 debian/copyright。
