# GCP Cloud Armor Terraform Module

## Overview

This Terraform module creates and manages Google Cloud Armor security policies.

## Features

- Create Cloud Armor security policies.
- Configure custom security rules.
- Allow or deny traffic based on source IP ranges.
- Configure WAF rules using CEL expressions.
- Support preview mode.
- Configure rule priorities and actions.

## Policy Type

CLOUD_ARMOR

## Inputs

- project_id
- name
- description
- rules

## Outputs

- security_policy_id
- security_policy_name
- security_policy_self_link

## Usage

Refer to sample.tf for module usage.
