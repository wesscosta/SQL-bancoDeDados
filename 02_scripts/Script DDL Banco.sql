-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema banco
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema banco
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `banco` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `banco` ;

-- -----------------------------------------------------
-- Table `banco`.`categorias`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`categorias` (
  `ID_Categoria` INT NOT NULL,
  `Categoria` TEXT NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Categoria`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`clientes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`clientes` (
  `ID_Cliente` INT NOT NULL,
  `Nome` TEXT NULL DEFAULT NULL,
  `Sobrenome` TEXT NULL DEFAULT NULL,
  `Data_Nascimento` TEXT NULL DEFAULT NULL,
  `Estado_Civil` TEXT NULL DEFAULT NULL,
  `Sexo` TEXT NULL DEFAULT NULL,
  `Email` TEXT NULL DEFAULT NULL,
  `Telefone` TEXT NULL DEFAULT NULL,
  `Renda_Anual` INT NULL DEFAULT NULL,
  `Qtd_Filhos` INT NULL DEFAULT NULL,
  `Escolaridade` TEXT NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Cliente`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`locais`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`locais` (
  `Cidade` TEXT NULL DEFAULT NULL,
  `Estado` TEXT NULL DEFAULT NULL,
  `Região` TEXT NULL DEFAULT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`lojas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`lojas` (
  `ID_Loja` INT NOT NULL,
  `Loja` TEXT NULL DEFAULT NULL,
  `Gerente` TEXT NULL DEFAULT NULL,
  `Endereco` TEXT NULL DEFAULT NULL,
  `Num_Funcionarios` INT NULL DEFAULT NULL,
  `Telefone` TEXT NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Loja`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`produtos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`produtos` (
  `ID_Produto` INT NOT NULL,
  `Nome_Produto` TEXT NULL DEFAULT NULL,
  `ID_Categoria` INT NULL DEFAULT NULL,
  `Marca_Produto` TEXT NULL DEFAULT NULL,
  `Num_Serie` TEXT NULL DEFAULT NULL,
  `Preco_Unit` INT NULL DEFAULT NULL,
  `Custo_Unit` DOUBLE NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Produto`),
  INDEX `fk_produtos_categorias` (`ID_Categoria` ASC) VISIBLE,
  CONSTRAINT `fk_produtos_categorias`
    FOREIGN KEY (`ID_Categoria`)
    REFERENCES `banco`.`categorias` (`ID_Categoria`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`pedidos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`pedidos` (
  `ID_Pedido` INT NOT NULL,
  `Data_Venda` TEXT NULL DEFAULT NULL,
  `ID_Loja` INT NULL DEFAULT NULL,
  `ID_Produto` INT NULL DEFAULT NULL,
  `ID_Cliente` INT NULL DEFAULT NULL,
  `Qtd_Vendida` INT NULL DEFAULT NULL,
  `Receita_Venda` INT NULL DEFAULT NULL,
  `Custo_Venda` DOUBLE NULL DEFAULT NULL,
  `Custo_Unit` DOUBLE NULL DEFAULT NULL,
  `Preco_Unit` INT NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Pedido`),
  INDEX `fk_pedidos_loja` (`ID_Loja` ASC) VISIBLE,
  INDEX `fk_pedidos_produtos` (`ID_Produto` ASC) VISIBLE,
  INDEX `fk_pedidos_clientes` (`ID_Cliente` ASC) VISIBLE,
  CONSTRAINT `fk_pedidos_clientes`
    FOREIGN KEY (`ID_Cliente`)
    REFERENCES `banco`.`clientes` (`ID_Cliente`),
  CONSTRAINT `fk_pedidos_loja`
    FOREIGN KEY (`ID_Loja`)
    REFERENCES `banco`.`lojas` (`ID_Loja`),
  CONSTRAINT `fk_pedidos_produtos`
    FOREIGN KEY (`ID_Produto`)
    REFERENCES `banco`.`produtos` (`ID_Produto`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `banco`.`vendedores`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `banco`.`vendedores` (
  `ID_Vendedor` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NULL DEFAULT NULL,
  `data_nascimento` DATE NULL DEFAULT NULL,
  `ID_Loja` INT NULL DEFAULT NULL,
  PRIMARY KEY (`ID_Vendedor`),
  UNIQUE INDEX `email` (`email` ASC) VISIBLE,
  INDEX `fk_vendedores_loja` (`ID_Loja` ASC) VISIBLE,
  CONSTRAINT `fk_vendedores_loja`
    FOREIGN KEY (`ID_Loja`)
    REFERENCES `banco`.`lojas` (`ID_Loja`))
ENGINE = InnoDB
AUTO_INCREMENT = 47
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
