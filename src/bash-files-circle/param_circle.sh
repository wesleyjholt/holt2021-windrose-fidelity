#!/bin/sh

wake_model=GaussYawVariableSpread
turbine_type=VestasV80_2MW
windrose=NantucketWindRose
opt_algorithm=SnoptWECAlgorithm
boundary_shape=CircleBoundary
initial_layout_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/initial-layout-${layout_number}.txt"
final_layout_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/final-layout-${layout_number}.yaml"
opt_info_directory="../results/opt-info/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/layout-${layout_number}/"
final_layout_figure_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/final-layout-${layout_number}"